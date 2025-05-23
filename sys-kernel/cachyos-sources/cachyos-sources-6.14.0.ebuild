# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="8"
ETYPE="sources"
K_WANT_GENPATCHES="base extras experimental"
K_GENPATCHES_VER="1"

inherit check-reqs kernel-2
detect_version
detect_arch

DESCRIPTION="CachyOS kernel sources"
HOMEPAGE="https://github.com/CachyOS/linux-cachyos"

CACHY_OS_KERNEL_PATCHES_COMMIT_HASH="aff044eb4da35a55c1f7d095c0b738be7d275fc7"
CACHY_OS_PKGBUILD_COMMIT_HASH="f94eef2c767cf31c2f25b8eef30068e60f279cc7"

SRC_URI="
	${KERNEL_URI} ${GENPATCHES_URI}
	https://github.com/CachyOS/kernel-patches/archive/${CACHY_OS_KERNEL_PATCHES_COMMIT_HASH}.tar.gz -> ${P}-patches.tar.gz
	https://github.com/CachyOS/linux-cachyos/archive/${CACHY_OS_PKGBUILD_COMMIT_HASH}.tar.gz -> ${P}-config.tar.gz
"
KEYWORDS="~alpha ~amd64 ~arm ~arm64 ~hppa ~loong ~m68k ~mips ~ppc ~ppc64 ~riscv ~s390 ~sparc ~x86"
IUSE="experimental +preempt-lazy acpi-call aufs spadfs handheld polly"
DEPEND="
polly? ( llvm-core/polly )
"

pkg_pretend() {
	CHECKREQS_DISK_BUILD="4G"
	check-reqs_pkg_pretend
}

src_unpack() {
	kernel-2_src_unpack

	mkdir "${WORKDIR}/cachyos" || die
	cd "${WORKDIR}/cachyos" || die

	unpack "${P}-patches.tar.gz"
	unpack "${P}-config.tar.gz"
}

src_prepare() {
	kernel-2_src_prepare
	rm "${S}/tools/testing/selftests/tc-testing/action-ebpf"

	CACHY_OS_PATCHES_DIR="${WORKDIR}/cachyos/kernel-patches-${CACHY_OS_KERNEL_PATCHES_COMMIT_HASH}/${KV_MAJOR}.${KV_MINOR}"
	CACHY_OS_CONFIG_DIR="${WORKDIR}/cachyos/linux-cachyos-${CACHY_OS_PKGBUILD_COMMIT_HASH}"

	eapply --ignore-whitespace -p1 "${CACHY_OS_PATCHES_DIR}/all/0001-cachyos-base-all.patch"

	# Apply scheduler patches
	eapply --ignore-whitespace -p1 "${CACHY_OS_PATCHES_DIR}/sched/0001-bore-cachy.patch"
	CACHY_OS_PROFILE="linux-cachyos"

	cp "${CACHY_OS_CONFIG_DIR}/${CACHY_OS_PROFILE}/config" .config || die
	sh "${CACHY_OS_CONFIG_DIR}/${CACHY_OS_PROFILE}/auto-cpu-optimization.sh" || die

	if use acpi-call; then
		eapply "${CACHY_OS_PATCHES_DIR}/misc/0001-acpi-call.patch"
	fi

	if use aufs; then
		eapply "${CACHY_OS_PATCHES_DIR}/misc/0001-aufs-6.14-merge-v20250210.patch"
	fi

	if use handheld; then
		eapply "${CACHY_OS_PATCHES_DIR}/misc/0001-handheld.patch"
	fi

	if use polly; then
		eapply "${CACHY_OS_PATCHES_DIR}/misc/0001-clang-polly.patch"
	fi

	eapply_user

	# Remove CachyOS's localversion
	find . -name "localversion*" -delete || die
	scripts/config -u LOCALVERSION || die

	# Enable CachyOS tweaks
	scripts/config -e CACHY || die

	# Selecting BORE scheduler
	scripts/config -e SCHED_BORE || die

	# Enable KCFI
	 scripts/config -e ARCH_SUPPORTS_CFI_CLANG -e CFI_CLANG -e CFI_AUTO_DEFAULT || die

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
		-d NUMA_BALANCING_DEFAULT_ENABLED

	# Change hostname
	scripts/config --set-str DEFAULT_HOSTNAME "gentoo" || die

	# LTO
	scripts/config -e LTO_NONE || die

	# 1000 Hz
	scripts/config -d HZ_300 -e HZ_1000 --set-val HZ 1000 || die

	# Setting NR_CPUS
	scripts/config --set-val NR_CPUS 320 || die

	# Setting full dynamic tick
	scripts/config -d HZ_PERIODIC -d NO_HZ_IDLE -d CONTEXT_TRACKING_FORCE \
		-e NO_HZ_FULL_NODEF -e NO_HZ_FULL -e NO_HZ -e NO_HZ_COMMON -e CONTEXT_TRACKING || die

	# Setting lazy preempt
	scripts/config -e PREEMPT_DYNAMIC -d PREEMPT -d PREEMPT_VOLUNTARY \
		-e PREEMPT_LAZY -d PREEMPT_NONE || die

	# Enable O3
	scripts/config -d CC_OPTIMIZE_FOR_PERFORMANCE -e CC_OPTIMIZE_FOR_PERFORMANCE_O3 || die

	# Enable bbr3
	scripts/config -m TCP_CONG_CUBIC \
            -d DEFAULT_CUBIC \
            -e TCP_CONG_BBR \
            -e DEFAULT_BBR \
            --set-str DEFAULT_TCP_CONG bbr \
            -m NET_SCH_FQ_CODEL \
            -e NET_SCH_FQ \
            -d CONFIG_DEFAULT_FQ_CODEL \
            -e CONFIG_DEFAULT_FQ || die

	# Enable MultiGen LRU
	scripts/config -e LRU_GEN -e LRU_GEN_ENABLED -d LRU_GEN_STATS || die

	# Enable VMA
	scripts/config -e PER_VMA_LOCK -d PER_VMA_LOCK_STATS || die

	# Enable Always THP
	scripts/config -d TRANSPARENT_HUGEPAGE_MADVISE -e TRANSPARENT_HUGEPAGE_ALWAYS || die

	# Enable DAMON (Deprecated)
	# scripts/config -e DAMON \
	# 	-e DAMON_VADDR \
	# 	-e DAMON_DBGFS \
	# 	-e DAMON_SYSFS \
	# 	-e DAMON_PADDR \
	# 	-e DAMON_RECLAIM \
	# 	-e DAMON_LRU_SORT || die

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
	optfeature "NVIDIA opensource module" "x11-drivers/nvidia-drivers[kernel-open]"
	optfeature "NVIDIA module" x11-drivers/nvidia-drivers
	optfeature "userspace KSM helper" sys-process/uksmd
	ewarn "Install sys-kernel/scx to Enable sched_ext schedulers"
	ewarn "Then enable/start scx service."
	einfo "For more info on this patchset, and how to report problems, see:"
	einfo "${HOMEPAGE}"
}

pkg_postrm() {
	kernel-2_pkg_postrm
}
