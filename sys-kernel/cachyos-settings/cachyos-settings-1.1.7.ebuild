# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
inherit udev tmpfiles
SETTINGS_COMMIT="00e9e479dab9f91510e8e98ab269a12ca60184de"
DESCRIPTION="Configuration files that tweak sysctl values, add udev rules to automatically set schedulers, and provide additional optimizations."
HOMEPAGE="https://github.com/CachyOS/CachyOS-Settings"
SRC_URI="https://github.com/CachyOS/CachyOS-Settings/archive/${SETTINGS_COMMIT}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/CachyOS-Settings-${SETTINGS_COMMIT}/usr/lib"
SUSRBIN="${WORKDIR}/CachyOS-Settings-${SETTINGS_COMMIT}/usr/bin"
IUSE="systemd zram"
REQUIRED_USE="zram? ( systemd )"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"

DEPEND="virtual/udev
	sys-apps/hdparm
	sys-process/procps
	zram? (
		sys-apps/zram-generator
		app-arch/zstd
	)
	systemd? ( sys-apps/systemd )
	!systemd? ( sys-apps/systemd-utils[tmpfiles] )"
RDEPEND="${DEPEND}"

src_prepare(){
if ! use zram; then rm -f "${S}/systemd/zram-generator.conf"
fi

if ! use systemd; then
	rm -rf "${S}/systemd/journald.conf.d"
	rm -rf "${S}/systemd/system.conf.d"
	rm -rf "${S}/systemd/system"
	rm -rf "${S}/systemd/user.conf.d"
fi
eapply_user

}

src_install() {
	insinto /etc
	doins -r "${S}/tmpfiles.d"
	doins -r "${S}/NetworkManager/conf.d"
	doins -r "${S}/modprobe.d"
	doins -r "${S}/sysctl.d"
	doins -r "${S}/systemd"

	udev_dorules "${S}/udev/rules.d/30-zram.rules"
	udev_dorules "${S}/udev/rules.d/40-hpet-permissions.rules"
	udev_dorules "${S}/udev/rules.d/50-sata.rules"
	udev_dorules "${S}/udev/rules.d/60-ioschedulers.rules"
	udev_dorules "${S}/udev/rules.d/69-hdparm.rules"
	udev_dorules "${S}/udev/rules.d/71-nvidia.rules"
	udev_dorules "${S}/udev/rules.d/99-cpu-dma-latency.rules"
	udev_dorules "${S}/udev/rules.d/99-ntsync.rules"

    dobin "${SUSRBIN}/amdpstate-guided"
    dobin "${SUSRBIN}/game-performance"
    dobin "${SUSRBIN}/kerver"
    dobin "${SUSRBIN}/ksmctl"
    dobin "${SUSRBIN}/ksmstats"
    dobin "${SUSRBIN}/pci-latency"
    dobin "${SUSRBIN}/sbctl-batch-sign"
    dobin "${SUSRBIN}/topmem"
    dobin "${SUSRBIN}/zink-run"
}

pkg_postinst() {
	udev_reload
	tmpfiles_process thp.conf
}

pkg_postrm() {
	udev_reload
}