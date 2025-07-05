# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="8"
ETYPE="sources"
K_WANT_GENPATCHES="base extras experimental"
K_GENPATCHES_VER="5"

inherit check-reqs kernel-2
detect_version
detect_arch

DESCRIPTION="CachyOS kernel sources"
HOMEPAGE="https://github.com/CachyOS/linux-cachyos"

CACHY_OS_KERNEL_PATCHES_COMMIT_HASH="3c9cc0e7b8f33870d106c5987dc61dc1c747dcf0"
CACHY_OS_PKGBUILD_COMMIT_HASH="77d40402384d117ad7043c160be442cbe645f88d"

SRC_URI="
	${KERNEL_URI} ${GENPATCHES_URI}
	https://github.com/CachyOS/kernel-patches/archive/${CACHY_OS_KERNEL_PATCHES_COMMIT_HASH}.tar.gz -> ${P}-patches.tar.gz
	https://github.com/CachyOS/linux-cachyos/archive/${CACHY_OS_PKGBUILD_COMMIT_HASH}.tar.gz -> ${P}-config.tar.gz
"
KEYWORDS="~alpha ~amd64 ~arm ~arm64 ~hppa ~loong ~m68k ~mips ~ppc ~ppc64 ~riscv ~s390 ~sparc ~x86"
IUSE="+bore bmq polly acpi-call aufs handheld experimental"
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

	eapply -Np1 "${CACHY_OS_PATCHES_DIR}/all/0001-cachyos-base-all.patch"

	if use bore; then
		eapply -Np1 "${CACHY_OS_PATCHES_DIR}/sched/0001-bore-cachy.patch"
		CACHY_OS_PROFILE="linux-cachyos"
	elif use bmq; then
		eapply -Np1 "${CACHY_OS_PATCHES_DIR}/sched/0001-prjc-cachy.patch"
		CACHY_OS_PROFILE="linux-cachyos-bmq"
	else
		CACHY_OS_PROFILE="linux-cachyos-eevdf"
	fi

	cp "${CACHY_OS_CONFIG_DIR}/${CACHY_OS_PROFILE}/config" cachyos-config || die

	if use acpi-call; then
		eapply "${CACHY_OS_PATCHES_DIR}/misc/0001-acpi-call.patch"
	fi

	if use aufs; then
		eapply "${CACHY_OS_PATCHES_DIR}/misc/0001-aufs-6.15-merge-v20250602.patch"
	fi

	if use handheld; then
		eapply "${CACHY_OS_PATCHES_DIR}/misc/0001-handheld.patch"
	fi

	if use polly; then
		eapply "${CACHY_OS_PATCHES_DIR}/misc/0001-clang-polly.patch"
	fi

	find . -name "localversion*" -delete || die
	scripts/config -u LOCALVERSION || die

	eapply_user
}

pkg_postinst() {
	kernel-2_pkg_postinst
	optfeature "NVIDIA opensource module" "x11-drivers/nvidia-drivers[kernel-open]"
	optfeature "NVIDIA module" x11-drivers/nvidia-drivers
	einfo "For more info on this patchset, and how to report problems, see:"
	einfo "${HOMEPAGE}"
}

pkg_postrm() {
	kernel-2_pkg_postrm
}
