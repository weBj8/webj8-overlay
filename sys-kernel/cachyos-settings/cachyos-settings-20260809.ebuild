# Copyright 2023-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit udev tmpfiles

# Keep date-based version ordering after the original snapshot ebuild.
SETTINGS_VERSION="1.4.0"
DESCRIPTION="System configuration tweaks for performance and responsiveness"
HOMEPAGE="https://github.com/CachyOS/CachyOS-Settings"
SRC_URI="https://github.com/CachyOS/CachyOS-Settings/archive/refs/tags/${SETTINGS_VERSION}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/CachyOS-Settings-${SETTINGS_VERSION}"

LICENSE="GPL-3 ISC"
SLOT="0"
KEYWORDS="~amd64"
IUSE="zram"

RDEPEND="
	virtual/udev
	sys-apps/hdparm
	sys-apps/pciutils
	sys-apps/systemd
	sys-apps/util-linux
	sys-libs/timezone-data
	net-wireless/iw
	zram? (
		sys-apps/zram-generator
		app-arch/zstd
	)
"

src_prepare() {
	# Gentoo installs iw in /usr/sbin, unlike CachyOS.
	sed -i 's|/usr/bin/iw |/usr/sbin/iw |g' usr/lib/iw-set-regdomain || die

	if ! use zram; then
		rm usr/lib/systemd/zram-generator.conf usr/lib/udev/rules.d/30-zram.rules || die
	fi

	default
}

src_install() {
	insinto /usr/lib
	doins -r usr/lib/NetworkManager usr/lib/modprobe.d usr/lib/modules-load.d
	doins -r usr/lib/sysctl.d usr/lib/systemd
	exeinto /usr/lib
	doexe usr/lib/iw-set-regdomain
	dobin usr/bin/pci-latency
	dotmpfiles usr/lib/tmpfiles.d/*.conf
	insinto /usr/share
	doins -r usr/share/X11
	udev_dorules usr/lib/udev/rules.d/*.rules
}

pkg_postinst() {
	udev_reload
	tmpfiles_process coredump.conf thp-shrinker.conf thp.conf
}

pkg_postrm() {
	udev_reload
}
