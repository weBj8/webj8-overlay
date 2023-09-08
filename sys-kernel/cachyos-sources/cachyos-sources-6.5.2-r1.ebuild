# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v3

EAPI="8"
ETYPE="sources"
EXTRAVERSION="-cachyos"
K_EXP_GENPATCHES_NOUSE="1"
K_WANT_GENPATCHES="base extras"
K_GENPATCHES_VER="3"

#inherit kernel-2 optfeature
inherit kernel-2
detect_version

DESCRIPTION="CachyOS kernel sources"
HOMEPAGE="https://github.com/CachyOS/linux-cachyos"

CACHY_OS_KERNEL_PATCHES_COMMIT_HASH="15789985490a834f78c9e6108d4fdc37e56c865a"
CACHY_OS_PKGBUILD_COMMIT_HASH="ca415578dda88c09d10d89a25aa912cb4a6b8f6b"

SRC_URI="
	${KERNEL_URI}
	${GENPATCHES_URI}
	https://github.com/CachyOS/kernel-patches/archive/${CACHY_OS_KERNEL_PATCHES_COMMIT_HASH}.tar.gz -> ${P}-patches.tar.gz
	https://github.com/CachyOS/linux-cachyos/archive/${CACHY_OS_PKGBUILD_COMMIT_HASH}.tar.gz -> ${P}-config.tar.gz
"

LICENSE="GPL-3"
KEYWORDS="~amd64"
IUSE="+eevdf-bore eevdf pds bmq tt bore tune-bore aufs bcachefs high-hz lrng spadfs gcc-lto gcc-lto-no-pie"
REQUIRED_USE="?? ( eevdf-bore eevdf pds bmq tt bore ) tune-bore? ( bore ) gcc-lto-no-pie? ( gcc-lto )"

src_unpack() {
	kernel-2_src_unpack

	mkdir "${WORKDIR}/cachyos" || die
	cd "${WORKDIR}/cachyos" || die

	unpack "${P}-patches.tar.gz"
	unpack "${P}-config.tar.gz"
}

src_prepare() {
	CACHY_OS_PATCHES_DIR="${WORKDIR}/cachyos/kernel-patches-${CACHY_OS_KERNEL_PATCHES_COMMIT_HASH}/${KV_MAJOR}.${KV_MINOR}"
	CACHY_OS_CONFIG_DIR="${WORKDIR}/cachyos/linux-cachyos-${CACHY_OS_PKGBUILD_COMMIT_HASH}"

	eapply "${CACHY_OS_PATCHES_DIR}/all/0001-cachyos-base-all.patch"

	if use eevdf-bore; then
		eapply "${CACHY_OS_PATCHES_DIR}/sched/0001-EEVDF-cachy.patch"
		eapply "${CACHY_OS_PATCHES_DIR}/sched/0001-bore-eevdf.patch"
		cp "${CACHY_OS_CONFIG_DIR}/linux-cachyos/config" .config || die
		sh "${CACHY_OS_CONFIG_DIR}/linux-cachyos/auto-cpu-optimization.sh" || die
	fi

	if use eevdf; then
		eapply "${CACHY_OS_PATCHES_DIR}/sched/0001-EEVDF-cachy.patch"
		cp "${CACHY_OS_CONFIG_DIR}/linux-cachyos-eevdf/config" .config || die
		sh "${CACHY_OS_CONFIG_DIR}/linux-cachyos-eevdf/auto-cpu-optimization.sh" || die
	fi

	if use pds; then
		eapply "${CACHY_OS_PATCHES_DIR}/sched/0001-prjc-cachy.patch"
		cp "${CACHY_OS_CONFIG_DIR}/linux-cachyos-pds/config" .config || die
		sh "${CACHY_OS_CONFIG_DIR}/linux-cachyos-pds/auto-cpu-optimization.sh" || die
	fi

	if use bmq; then
		eapply "${CACHY_OS_PATCHES_DIR}/sched/0001-prjc-cachy.patch"
		cp "${CACHY_OS_CONFIG_DIR}/linux-cachyos-bmq/config" .config || die
		sh "${CACHY_OS_CONFIG_DIR}/linux-cachyos-bmq/auto-cpu-optimization.sh" || die
	fi

	if use tt; then
		eapply "${CACHY_OS_PATCHES_DIR}/sched/0001-tt-cachy.patch"
		cp "${CACHY_OS_CONFIG_DIR}/linux-cachyos-tt/config" .config || die
		sh "${CACHY_OS_CONFIG_DIR}/linux-cachyos-tt/auto-cpu-optimization.sh" || die
	fi

	if use bore; then
		if use tune-bore; then
			eapply "${CACHY_OS_PATCHES_DIR}/misc/0001-bore-tuning-sysctl.patch"
		fi
		eapply "${CACHY_OS_PATCHES_DIR}/sched/0001-bore-cachy.patch"
		cp "${CACHY_OS_CONFIG_DIR}/linux-cachyos-bore/config" .config || die
		sh "${CACHY_OS_CONFIG_DIR}/linux-cachyos-bore/auto-cpu-optimization.sh" || die
	fi

	if use aufs; then
		eapply "${CACHY_OS_PATCHES_DIR}/misc/0001-aufs-6.5-merge-v20230904.patch"
	fi

	if use bcachefs; then
		eapply "${CACHY_OS_PATCHES_DIR}/misc/0001-bcachefs.patch"
	fi

	if use high-hz; then
		eapply "${CACHY_OS_PATCHES_DIR}/misc/0001-high-hz.patch"
	fi

	if use lrng; then
		eapply "${CACHY_OS_PATCHES_DIR}/misc/0001-lrng.patch"
	fi

	if use spadfs; then
		eapply "${CACHY_OS_PATCHES_DIR}/misc/0001-spadfs-6.5-merge-v1.0.17.patch"
	fi

	if use gcc-lto; then
		eapply "${CACHY_OS_PATCHES_DIR}/misc/gcc-lto/0001-gcc-lto.patch"
		if use gcc-lto-no-pie; then
			eapply "${CACHY_OS_PATCHES_DIR}/misc/gcc-lto/0002-gcc-lto-no-pie.patch"
		fi
	fi

	eapply_user

	# Remove CachyOS's localversion
	find . -name "localversion*" -delete || die
	scripts/config -u LOCALVERSION || die

	# Enable CachyOS tweaks
	scripts/config -e CACHY || die

	# Enable PDS
	if use pds; then
		scripts/config -e SCHED_ALT -d SCHED_BMQ -e SCHED_PDS -e PSI_DEFAULT_DISABLED || die
	fi

	# Enable BMQ
	if use bmq; then
		scripts/config -e SCHED_ALT -e SCHED_BMQ -d SCHED_PDS -e PSI_DEFAULT_DISABLED || die
	fi

	# Enable TT
	if use tt; then
		scripts/config -e TT_SCHED -e TT_ACCOUNTING_STATS || die
	fi

	# Enable BORE
	if use bore; then
		scripts/config -e SCHED_BORE || die
	fi

	if use eevdf-bore; then
		scripts/config -e SCHED_BORE || die
	fi

	# Change hostname
	scripts/config --set-str DEFAULT_HOSTNAME "gentoo" || die

	# Enable kCFI
	scripts/config -e ARCH_SUPPORTS_CFI_CLANG -e CFI_CLANG || die

	# Use LLVM Thin LTO
	scripts/config -e LTO -e LTO_CLANG -e ARCH_SUPPORTS_LTO_CLANG \
		-e ARCH_SUPPORTS_LTO_CLANG_THIN -d LTO_NONE -e HAS_LTO_CLANG \
		-d LTO_CLANG_FULL -e LTO_CLANG_THIN -e HAVE_GCC_PLUGINS || die

	# Use 500 hz
	scripts/config -e HZ_500 --set-val HZ 500

	# Disable NUMA
	scripts/config -d NUMA \
		-d AMD_NUMA \
		-d X86_64_ACPI_NUMA \
		-d NODES_SPAN_OTHER_NODES \
		-d NUMA_EMU \
		-d USE_PERCPU_NUMA_NODE_ID \
		-d ACPI_NUMA \
		-d ARCH_SUPPORTS_NUMA_BALANCING \
		-d NODES_SHIFT \
		-u NODES_SHIFT \
		-d NEED_MULTIPLE_NODES \
		-d NUMA_BALANCING \
		-d NUMA_BALANCING_DEFAULT_ENABLED || die

	# Setting NR_CPUS
	scripts/config --set-val NR_CPUS 320 || die

	# Setting Performance Governor
	scripts/config -d CPU_FREQ_DEFAULT_GOV_SCHEDUTIL -e CPU_FREQ_DEFAULT_GOV_PERFORMANCE || die

	# Setting full dynamic tick
	scripts/config -d HZ_PERIODIC -d NO_HZ_IDLE -d CONTEXT_TRACKING_FORCE \
		-e NO_HZ_FULL_NODEF -e NO_HZ_FULL -e NO_HZ -e NO_HZ_COMMON -e CONTEXT_TRACKING || die

	# Setting full preempt
	scripts/config -e PREEMPT_BUILD -d PREEMPT_NONE -d PREEMPT_VOLUNTARY \
		-e PREEMPT -e PREEMPT_COUNT -e PREEMPTION -e PREEMPT_DYNAMIC || die

	# Enable O3
	scripts/config -d CC_OPTIMIZE_FOR_PERFORMANCE -e CC_OPTIMIZE_FOR_PERFORMANCE_O3 || die

	# Enable bbr3
	scripts/config -m TCP_CONG_CUBIC \
		-d DEFAULT_CUBIC \
		-e TCP_CONG_BBR \
		-e DEFAULT_BBR \
		--set-str DEFAULT_TCP_CONG bbr || die

	scripts/config -m NET_SCH_FQ_CODEL \
		-e NET_SCH_FQ \
		-d DEFAULT_FQ_CODEL \
		-e DEFAULT_FQ \
		--set-str DEFAULT_NET_SCH fq || die

	# Enable MultiGen LRU
	scripts/config -e LRU_GEN -e LRU_GEN_ENABLED -d LRU_GEN_STATS || die

	# Enable VMA
	scripts/config -e PER_VMA_LOCK -d PER_VMA_LOCK_STATS || die

	# Enable Always THP
	scripts/config -d TRANSPARENT_HUGEPAGE_MADVISE -e TRANSPARENT_HUGEPAGE_ALWAYS || die

	# Enable DAMON
	scripts/config -e DAMON \
		-e DAMON_VADDR \
		-e DAMON_DBGFS \
		-e DAMON_SYSFS \
		-e DAMON_PADDR \
		-e DAMON_RECLAIM \
		-e DAMON_LRU_SORT || die

	# Enable LRNG
	if use lrng; then
		scripts/config -d RANDOM_DEFAULT_IMPL \
			-e LRNG \
			-e LRNG_SHA256 \
			-e LRNG_COMMON_DEV_IF \
			-e LRNG_DRNG_ATOMIC \
			-e LRNG_SYSCTL \
			-e LRNG_RANDOM_IF \
			-e LRNG_AIS2031_NTG1_SEEDING_STRATEGY \
			-m LRNG_KCAPI_IF \
			-m LRNG_HWRAND_IF \
			-e LRNG_DEV_IF \
			-e LRNG_RUNTIME_ES_CONFIG \
			-e LRNG_IRQ_DFLT_TIMER_ES \
			-d LRNG_SCHED_DFLT_TIMER_ES \
			-e LRNG_TIMER_COMMON \
			-d LRNG_COLLECTION_SIZE_256 \
			-d LRNG_COLLECTION_SIZE_512 \
			-e LRNG_COLLECTION_SIZE_1024 \
			-d LRNG_COLLECTION_SIZE_2048 \
			-d LRNG_COLLECTION_SIZE_4096 \
			-d LRNG_COLLECTION_SIZE_8192 \
			--set-val LRNG_COLLECTION_SIZE 1024 \
			-e LRNG_HEALTH_TESTS \
			--set-val LRNG_RCT_CUTOFF 31 \
			--set-val LRNG_APT_CUTOFF 325 \
			-e LRNG_IRQ \
			-e LRNG_CONTINUOUS_COMPRESSION_ENABLED \
			-d LRNG_CONTINUOUS_COMPRESSION_DISABLED \
			-e LRNG_ENABLE_CONTINUOUS_COMPRESSION \
			-e LRNG_SWITCHABLE_CONTINUOUS_COMPRESSION \
			--set-val LRNG_IRQ_ENTROPY_RATE 256 \
			-e LRNG_JENT \
			--set-val LRNG_JENT_ENTROPY_RATE 16 \
			-e LRNG_CPU \
			--set-val LRNG_CPU_FULL_ENT_MULTIPLIER 1 \
			--set-val LRNG_CPU_ENTROPY_RATE 8 \
			-e LRNG_SCHED \
			--set-val LRNG_SCHED_ENTROPY_RATE 4294967295 \
			-e LRNG_DRNG_CHACHA20 \
			-m LRNG_DRBG \
			-m LRNG_DRNG_KCAPI \
			-e LRNG_SWITCH \
			-e LRNG_SWITCH_HASH \
			-m LRNG_HASH_KCAPI \
			-e LRNG_SWITCH_DRNG \
			-m LRNG_SWITCH_DRBG \
			-m LRNG_SWITCH_DRNG_KCAPI \
			-e LRNG_DFLT_DRNG_CHACHA20 \
			-d LRNG_DFLT_DRNG_DRBG \
			-d LRNG_DFLT_DRNG_KCAPI \
			-e LRNG_TESTING_MENU \
			-d LRNG_RAW_HIRES_ENTROPY \
			-d LRNG_RAW_JIFFIES_ENTROPY \
			-d LRNG_RAW_IRQ_ENTROPY \
			-d LRNG_RAW_RETIP_ENTROPY \
			-d LRNG_RAW_REGS_ENTROPY \
			-d LRNG_RAW_ARRAY \
			-d LRNG_IRQ_PERF \
			-d LRNG_RAW_SCHED_HIRES_ENTROPY \
			-d LRNG_RAW_SCHED_PID_ENTROPY \
			-d LRNG_RAW_SCHED_START_TIME_ENTROPY \
			-d LRNG_RAW_SCHED_NVCSW_ENTROPY \
			-d LRNG_SCHED_PERF \
			-d LRNG_ACVT_HASH \
			-d LRNG_RUNTIME_MAX_WO_RESEED_CONFIG \
			-d LRNG_TEST_CPU_ES_COMPRESSION \
			-e LRNG_SELFTEST \
			-d LRNG_SELFTEST_PANIC \
			-d LRNG_RUNTIME_FORCE_SEEDING_DISABLE || die
	fi

	# Disable DEBUG
	scripts/config -d DEBUG_INFO \
		-d DEBUG_INFO_BTF \
		-d DEBUG_INFO_DWARF4 \
		-d DEBUG_INFO_DWARF5 \
		-d PAHOLE_HAS_SPLIT_BTF \
		-d DEBUG_INFO_BTF_MODULES \
		-d SLUB_DEBUG \
		-d PM_DEBUG \
		-d PM_ADVANCED_DEBUG \
		-d PM_SLEEP_DEBUG \
		-d ACPI_DEBUG \
		-d SCHED_DEBUG \
		-d LATENCYTOP \
		-d DEBUG_PREEMPT || die

	# Enable USER_NS_UNPRIVILEGED
	scripts/config -e USER_NS || die
	mv .config cachyos-config || die
}

pkg_postinst() {
	kernel-2_pkg_postinst

	#optfeature "userspace KSM helper" sys-process/uksmd
	#optfeature "auto nice daemon" app-admin/ananicy-cpp
}

pkg_postrm() {
	kernel-2_pkg_postrm
}
