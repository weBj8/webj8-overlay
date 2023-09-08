# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v3

EAPI="8"
ETYPE="sources"
EXTRAVERSION="-cachyos"
K_EXP_GENPATCHES_NOUSE="1"
K_WANT_GENPATCHES="base extras"
K_GENPATCHES_VER="3"

inherit kernel-2 optfeature
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
		sh "${CACHY_OS_CONFIG_DIR}/linux-cachyos/auto-cpu-optimization.sh"
	fi

	if use eevdf; then
		eapply "${CACHY_OS_PATCHES_DIR}/sched/0001-EEVDF-cachy.patch"
		cp "${CACHY_OS_CONFIG_DIR}/linux-cachyos-eevdf/config" .config || die
		sh "${CACHY_OS_CONFIG_DIR}/linux-cachyos-eevdf/auto-cpu-optimization.sh"
	fi

	if use pds; then
		eapply "${CACHY_OS_PATCHES_DIR}/sched/0001-prjc-cachy.patch"
		cp "${CACHY_OS_CONFIG_DIR}/linux-cachyos-pds/config" .config || die
		sh "${CACHY_OS_CONFIG_DIR}/linux-cachyos-pds/auto-cpu-optimization.sh"
	fi

	if use bmq; then
		eapply "${CACHY_OS_PATCHES_DIR}/sched/0001-prjc-cachy.patch"
		cp "${CACHY_OS_CONFIG_DIR}/linux-cachyos-bmq/config" .config || die
		sh "${CACHY_OS_CONFIG_DIR}/linux-cachyos-bmq/auto-cpu-optimization.sh"
	fi

	if use tt; then
		eapply "${CACHY_OS_PATCHES_DIR}/sched/0001-tt-cachy.patch"
		cp "${CACHY_OS_CONFIG_DIR}/linux-cachyos-tt/config" .config || die
		sh "${CACHY_OS_CONFIG_DIR}/linux-cachyos-tt/auto-cpu-optimization.sh"
	fi

	if use bore; then
		if use tune-bore; then
			eapply "${CACHY_OS_PATCHES_DIR}/misc/0001-bore-tuning-sysctl.patch"
		fi
		eapply "${CACHY_OS_PATCHES_DIR}/sched/0001-bore-cachy.patch"
		cp "${CACHY_OS_CONFIG_DIR}/linux-cachyos-bore/config" .config || die
		sh "${CACHY_OS_CONFIG_DIR}/linux-cachyos-bore/auto-cpu-optimization.sh"
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
	find . -name "localversion*" -delete
	scripts/config -u LOCALVERSION

	# Enable CachyOS tweaks
	scripts/config -e CACHY

	# Enable PDS
	if use pds; then
		scripts/config -e SCHED_ALT -d SCHED_BMQ -e SCHED_PDS -e PSI_DEFAULT_DISABLED
	fi

	# Enable BMQ
	if use bmq; then
		scripts/config -e SCHED_ALT -e SCHED_BMQ -d SCHED_PDS -e PSI_DEFAULT_DISABLED
	fi

	# Enable TT
	if use tt; then
		scripts/config -e TT_SCHED -e TT_ACCOUNTING_STATS
	fi

	# Enable BORE
	if use bore; then
		scripts/config -e SCHED_BORE
	fi

	if use eevdf-bore; then
		scripts/config -e SCHED_BORE
	fi

	# Change hostname
	scripts/config --set-str DEFAULT_HOSTNAME "gentoo"
}

pkg_postinst() {
	kernel-2_pkg_postinst

	#optfeature "userspace KSM helper" sys-process/uksmd
	#optfeature "auto nice daemon" app-admin/ananicy-cpp
}

pkg_postrm() {
	kernel-2_pkg_postrm
}
