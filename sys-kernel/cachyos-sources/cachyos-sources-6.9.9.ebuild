# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v3

EAPI="8"
ETYPE="sources"
EXTRAVERSION="-cachyos"
K_EXP_GENPATCHES_NOUSE="1"
K_WANT_GENPATCHES="base extras"
K_GENPATCHES_VER="10"

inherit kernel-2 optfeature
detect_version

DESCRIPTION="CachyOS kernel sources"
HOMEPAGE="https://github.com/CachyOS/linux-cachyos"

CACHY_OS_KERNEL_PATCHES_COMMIT_HASH="d1c68190ff202755f11516678e9bf68afbf7f469"
CACHY_OS_PKGBUILD_COMMIT_HASH="bf423f60f777d1082d101e0944dcd19a64e4afa3"

SRC_URI="
	${KERNEL_URI}
	${GENPATCHES_URI}
	https://github.com/CachyOS/kernel-patches/archive/${CACHY_OS_KERNEL_PATCHES_COMMIT_HASH}.tar.gz -> ${P}-patches.tar.gz
	https://github.com/CachyOS/linux-cachyos/archive/${CACHY_OS_PKGBUILD_COMMIT_HASH}.tar.gz -> ${P}-config.tar.gz
"

LICENSE="GPL-3"
KEYWORDS="~amd64"
IUSE="sched-ext +bore intel acpi-call aufs le9uo ntsync spadfs slab steam-deck-oled"
REQUIRED_USE=""

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
	if use sched-ext; then
		if use bore; then
            eapply "${CACHY_OS_PATCHES_DIR}/sched/0001-sched-ext.patch"
            eapply "${CACHY_OS_PATCHES_DIR}/sched/0001-bore-cachy-ext.patch"
			CACHY_OS_PROFILE="linux-cachyos"
		else
            eapply "${CACHY_OS_PATCHES_DIR}/sched/0001-sched-ext.patch"
			CACHY_OS_PROFILE="linux-cachyos-sched-ext"
		fi
	else
		if use bore; then
            eapply "${CACHY_OS_PATCHES_DIR}/sched/0001-bore-cachy.patch"
			CACHY_OS_PROFILE="linux-cachyos-bore"
		else
			CACHY_OS_PROFILE="linux-cachyos-eevdf"
		fi
	fi

	cp "${CACHY_OS_CONFIG_DIR}/${CACHY_OS_PROFILE}/config" .config || die
	sh "${CACHY_OS_CONFIG_DIR}/${CACHY_OS_PROFILE}/auto-cpu-optimization.sh" || die


	if use intel; then
		eapply "${CACHY_OS_PATCHES_DIR}/intel/0001-intel-thread-director.patch"
	fi

	if use acpi-call; then
		eapply "${CACHY_OS_PATCHES_DIR}/misc/0001-acpi-call.patch"
	fi

	if use aufs; then
		eapply "${CACHY_OS_PATCHES_DIR}/misc/0001-aufs-6.9-merge-v20240701.patch"
	fi

	if use le9uo; then
		eapply "${CACHY_OS_PATCHES_DIR}/misc/0001-le9uo.patch"
	fi

	if use ntsync; then
		eapply "${CACHY_OS_PATCHES_DIR}/misc/0001-ntsync.patch"
	fi

	if use spadfs; then
		eapply "${CACHY_OS_PATCHES_DIR}/misc/0001-spadfs-6.9-merge-v1.0.19.patch"
	fi

	if use slab; then
		eapply "${CACHY_OS_PATCHES_DIR}/misc/0002-slab.patch"
	fi

    if use steam-deck-oled; then
        eapply "${CACHY_OS_PATCHES_DIR}/misc/0001-wifi-ath11k-Rename-QCA2066-fw-dir-to-QCA206X.patch"
    fi

	eapply_user

	# Remove CachyOS's localversion
	find . -name "localversion*" -delete || die
	scripts/config -u LOCALVERSION || die

	# Enable CachyOS tweaks
	scripts/config -e CACHY || die

	if use sched-ext; then
		if use bore; then
            scripts/config -e SCHED_CLASS_EXT -e SCHED_BORE --set-val MIN_BASE_SLICE_NS 1000000 || die
		else
            scripts/config -e SCHED_CLASS_EXT || die
		fi
	else
		if use bore; then
            scripts/config -e SCHED_BORE --set-val MIN_BASE_SLICE_NS 1000000 || die
		fi
	fi

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

	# Enable DAMON
	scripts/config -e DAMON \
		-e DAMON_VADDR \
		-e DAMON_DBGFS \
		-e DAMON_SYSFS \
		-e DAMON_PADDR \
		-e DAMON_RECLAIM \
		-e DAMON_LRU_SORT || die

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
