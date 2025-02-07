# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v3

EAPI="8"
ETYPE="sources"
K_WANT_GENPATCHES="base extras experimental"
K_GENPATCHES_VER="2"
# K_EXP_GENPATCHES_NOUSE="1"
K_USEPV="1"

EXTRAVERSION="-cachyos"

# make sure kernel-2 know right version without guess
CKV="$(ver_cut 1-3)"

inherit check-reqs kernel-2 optfeature
detect_version
detect_arch

DESCRIPTION="CachyOS kernel sources"
HOMEPAGE="https://github.com/CachyOS/linux-cachyos"

CACHY_OS_KERNEL_PATCHES_COMMIT_HASH="707cc86911e9e0210f301f16f16123c34264822c"
CACHY_OS_PKGBUILD_COMMIT_HASH="dc68edaecdd85fa5f55488ebaff7434c9287ee56"

SRC_URI="
	${KERNEL_URI} ${GENPATCHES_URI}
	https://github.com/CachyOS/kernel-patches/archive/${CACHY_OS_KERNEL_PATCHES_COMMIT_HASH}.tar.gz -> ${P}-patches.tar.gz
	https://github.com/CachyOS/linux-cachyos/archive/${CACHY_OS_PKGBUILD_COMMIT_HASH}.tar.gz -> ${P}-config.tar.gz
"
KEYWORDS="~alpha ~amd64 ~arm ~arm64 ~hppa ~loong ~m68k ~mips ~ppc ~ppc64 ~riscv ~s390 ~sparc ~x86"

LICENSE="GPL-3"
KEYWORDS="~amd64"
IUSE="experimental +preempt-lazy acpi-call aufs spadfs handheld polly"
DEPEND="
polly? ( sys-devel/polly )
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
	# if use bore; then
	# else
	#     eapply "${CACHY_OS_PATCHES_DIR}/sched/0001-sched-ext.patch"
	# 	CACHY_OS_PROFILE="linux-cachyos-sched-ext"
	# fi

	cp "${CACHY_OS_CONFIG_DIR}/${CACHY_OS_PROFILE}/config" .config || die
	sh "${CACHY_OS_CONFIG_DIR}/${CACHY_OS_PROFILE}/auto-cpu-optimization.sh" || die

	if use acpi-call; then
		eapply "${CACHY_OS_PATCHES_DIR}/misc/0001-acpi-call.patch"
	fi

	if use aufs; then
		eapply "${CACHY_OS_PATCHES_DIR}/misc/0001-aufs-6.13-merge-v20250127.patch"
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

	scripts/config -e SCHED_CLASS_EXT -e SCHED_BORE --set-val MIN_BASE_SLICE_NS 1000000 || die
	# if use sched-ext; then
	# 	if use bore; then
	#         scripts/config -e SCHED_CLASS_EXT -e SCHED_BORE --set-val MIN_BASE_SLICE_NS 1000000 || die
	# 	else
	#         scripts/config -e SCHED_CLASS_EXT || die
	# 	fi
	# else
	# 	if use bore; then
	#         scripts/config -e SCHED_BORE --set-val MIN_BASE_SLICE_NS 1000000 || die
	# 	fi
	# fi

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

	# Enable DAMON (Deprecated)
	# scripts/config -e DAMON \
	# 	-e DAMON_VADDR \
	# 	-e DAMON_DBGFS \
	# 	-e DAMON_SYSFS \
	# 	-e DAMON_PADDR \
	# 	-e DAMON_RECLAIM \
	# 	-e DAMON_LRU_SORT || die

	# if ! use sched-ext; then
	# 	scripts/config -d DEBUG_INFO \
	#         -d DEBUG_INFO_BTF \
	#         -d DEBUG_INFO_DWARF4 \
	#         -d DEBUG_INFO_DWARF5 \
	#         -d PAHOLE_HAS_SPLIT_BTF \
	#         -d DEBUG_INFO_BTF_MODULES \
	#         -d SLUB_DEBUG \
	#         -d PM_DEBUG \
	#         -d PM_ADVANCED_DEBUG \
	#         -d PM_SLEEP_DEBUG \
	#         -d ACPI_DEBUG \
	#         -d SCHED_DEBUG \
	#         -d LATENCYTOP \
	#         -d DEBUG_PREEMPT || die
	# fi

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

	#optfeature "auto nice daemon" app-admin/ananicy-cpp
}

pkg_postrm() {
	kernel-2_pkg_postrm
}
