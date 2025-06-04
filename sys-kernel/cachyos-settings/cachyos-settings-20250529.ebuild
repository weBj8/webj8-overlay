# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
inherit udev tmpfiles
SETTINGS_COMMIT="d92ed1dab68515050a585d2a13630ead819e0a12"
DESCRIPTION="Configuration files that tweak sysctl values, add udev rules to automatically set schedulers, and provide additional optimizations."
HOMEPAGE="https://github.com/CachyOS/CachyOS-Settings"
SRC_URI="https://github.com/CachyOS/CachyOS-Settings/archive/${SETTINGS_COMMIT}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/CachyOS-Settings-${SETTINGS_COMMIT}/"
IUSE="zram"
REQUIRED_USE=""

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"

DEPEND="virtual/udev
	sys-apps/hdparm
	sys-apps/systemd
	zram? (
		sys-apps/zram-generator
		app-arch/zstd
	)"

RDEPEND="${DEPEND}"

src_prepare(){
	if ! use zram; then
		rm -f "${S}/systemd/zram-generator.conf"
	fi

	eapply_user
}

src_install() {
	insinto /usr/lib
	doins -r "${S}/usr/lib/NetworkManager"
	doins -r "${S}/usr/lib/modprobe.d"
	doins -r "${S}/usr/lib/modules-load.d"
	doins -r "${S}/usr/lib/sysctl.d"
	doins -r "${S}/usr/lib/systemd"
	dotmpfiles "${S}/usr/lib/tmpfiles.d/coredump.conf"
	dotmpfiles "${S}/usr/lib/tmpfiles.d/disable-zswap.conf"
	dotmpfiles "${S}/usr/lib/tmpfiles.d/optimize-interruptfreq.conf"
	dotmpfiles "${S}/usr/lib/tmpfiles.d/thp-shrinker.conf"
	dotmpfiles "${S}/usr/lib/tmpfiles.d/thp.conf"
	insinto /usr/share
	doins -r "${S}/usr/share/X11"
	udev_dorules "${S}/usr/lib/udev/rules.d/30-zram.rules"
	udev_dorules "${S}/usr/lib/udev/rules.d/40-hpet-permissions.rules"
	udev_dorules "${S}/usr/lib/udev/rules.d/50-sata.rules"
	udev_dorules "${S}/usr/lib/udev/rules.d/60-ioschedulers.rules"
	udev_dorules "${S}/usr/lib/udev/rules.d/69-hdparm.rules"
	udev_dorules "${S}/usr/lib/udev/rules.d/71-nvidia.rules"
	udev_dorules "${S}/usr/lib/udev/rules.d/99-cpu-dma-latency.rules"
}

pkg_postinst() {
	udev_reload
	tmpfiles_process coredump.conf disable-zswap.conf optimize-interruptfreq.conf thp-shrinker.conf thp.conf
}

pkg_postrm() {
	udev_reload
}