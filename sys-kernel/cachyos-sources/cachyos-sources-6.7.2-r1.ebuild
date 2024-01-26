# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v3

EAPI="8"
ETYPE="sources"
EXTRAVERSION="-cachyos"
K_EXP_GENPATCHES_NOUSE="1"
K_WANT_GENPATCHES="base extras"
K_GENPATCHES_VER="4"

inherit kernel-2 optfeature
detect_version

DESCRIPTION="CachyOS kernel sources"
HOMEPAGE="https://github.com/CachyOS/linux-cachyos"

CACHY_OS_KERNEL_PATCHES_COMMIT_HASH="c43e7415c4fd0dd8cc7f8b023be36fd50182fd56"
CACHY_OS_PKGBUILD_COMMIT_HASH="61e2f30833b4391a1d991cb38409a0af4ca214a0"

SRC_URI="
	${KERNEL_URI}
	${GENPATCHES_URI}
	https://github.com/CachyOS/kernel-patches/archive/${CACHY_OS_KERNEL_PATCHES_COMMIT_HASH}.tar.gz -> ${P}-patches.tar.gz
	https://github.com/CachyOS/linux-cachyos/archive/${CACHY_OS_PKGBUILD_COMMIT_HASH}.tar.gz -> ${P}-config.tar.gz
"

LICENSE="GPL-3"
KEYWORDS="~amd64"
IUSE="+sched-ext +bore bore-tuning lrng gcc-extra-flags intel amd-hdr vmap ntsync spadfs v4l2-loopback"
REQUIRED_USE="bore-tuning? ( bore )"

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

	# Apply scheduler patches
	use sched-ext && eapply "${CACHY_OS_PATCHES_DIR}/sched/0001-sched-ext.patch"
	use bore && eapply "${CACHY_OS_PATCHES_DIR}/sched/0001-bore-cachy.patch"
	use bore-tuning && eapply "${CACHY_OS_PATCHES_DIR}/misc/bore-tuning-sysctl.patch"

	if use sched-ext; then
		if use bore; then
			CACHY_OS_PROFILE="linux-cachyos"
		else
			CACHY_OS_PROFILE="linux-cachyos-sched-ext"
		fi
	else
		if use bore; then
			CACHY_OS_PROFILE="linux-cachyos-bore"
		else
			CACHY_OS_PROFILE="linux-cachyos-eevdf"
		fi
	fi

	cp "${CACHY_OS_CONFIG_DIR}/${CACHY_OS_PROFILE}/config" .config || die
	sh "${CACHY_OS_CONFIG_DIR}/${CACHY_OS_PROFILE}/auto-cpu-optimization.sh" || die

	if use lrng; then
		eapply "${CACHY_OS_PATCHES_DIR}/misc/0001-lrng.patch"
	fi

	if use gcc-extra-flags; then
		eapply "${CACHY_OS_PATCHES_DIR}/misc/0001-Add-extra-GCC-optimization-flags.patch"
	fi

	if use intel; then
		eapply "${CACHY_OS_PATCHES_DIR}/intel/0001-intel-thread-director.patch"
		eapply "${CACHY_OS_PATCHES_DIR}/intel/0002-avoid-recalculations.patch"
		eapply "${CACHY_OS_PATCHES_DIR}/intel/0003-pcores-fair.patch"
	fi

	if use amd-hdr; then
		eapply "${CACHY_OS_PATCHES_DIR}/misc/0001-amd-hdr.patch"
	fi

	if use vmap; then
		eapply "${CACHY_OS_PATCHES_DIR}/misc/0001-mm-Mitigate-a-vmap-lock-contention-v3.patch"
	fi

	if use ntsync; then
		eapply "${CACHY_OS_PATCHES_DIR}/misc/0001-ntsync.patch"
	fi

	if use v4l2-loopback; then
		eapply "${CACHY_OS_PATCHES_DIR}/misc/v4l2loopback.patch"
	fi
	
	if use spadfs; then
		eapply "${CACHY_OS_PATCHES_DIR}/misc/0001-spadfs-6.7-merge-v1.0.18.patch"
	fi

	eapply_user

	# Remove CachyOS's localversion
	find . -name "localversion*" -delete || die
	scripts/config -u LOCALVERSION || die

	# Enable CachyOS tweaks
	scripts/config -e CACHY || die

	# Enable SCX
	if use sched-ext; then
		scripts/config -e SCHED_CLASS_EXT || die
	fi

	# Enable BORE
	if use bore; then
		scripts/config -e SCHED_BORE || die
	fi

	# Change hostname
	scripts/config --set-str DEFAULT_HOSTNAME "gentoo" || die

	# LTO
	scripts/config -e LTO_NONE || die

	# 500 Hz
	scripts/config -e HZ_500 --set-val HZ 500 || die

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

	if ! use sched-ext; then
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
	fi

	# Enable USER_NS_UNPRIVILEGED
	scripts/config -e USER_NS || die

	mv .config cachyos-config || die
}

pkg_postinst() {
	kernel-2_pkg_postinst

	optfeature "userspace KSM helper" sys-process/uksmd
	#optfeature "auto nice daemon" app-admin/ananicy-cpp
}

pkg_postrm() {
	kernel-2_pkg_postrm
}
