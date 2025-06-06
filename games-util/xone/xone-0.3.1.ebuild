# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit linux-mod-r1

COMMIT="197b160f7806d7d27117b12198cacb7656a07f1f"
XONE_DRIVER_VERSION="201707-1cd6a87c-623f-4407-a52d-c31be49e925c_e19f60808bdcbfbd3c3df6be3e71ffc52e43261e"
XONE_045E_02E6_DRIVER_VERSION="201512-20810869_8ce2975a7fbaa06bcfb0d8762a6275a1cf7c1dd3"

DESCRIPTION="Linux kernel driver for Xbox One and Xbox Series X|S accessories"
HOMEPAGE="https://github.com/dlundqvist/xone"
SRC_URI="
	mirror+https://github.com/dlundqvist/xone/archive/${COMMIT}.tar.gz -> ${P}.tar.gz
	https://catalog.s.download.windowsupdate.com/d/msdownload/update/driver/drvs/${XONE_DRIVER_VERSION:0:4}/${XONE_DRIVER_VERSION:4:2}/${XONE_DRIVER_VERSION:7}.cab
		-> ${PN}-driver-${XONE_DRIVER_VERSION}.cab
	https://catalog.s.download.windowsupdate.com/d/msdownload/update/driver/drvs/${XONE_045E_02E6_DRIVER_VERSION:0:4}/${XONE_045E_02E6_DRIVER_VERSION:4:2}/${XONE_045E_02E6_DRIVER_VERSION:7}.cab
		-> ${PN}-driver-${XONE_045E_02E6_DRIVER_VERSION}.cab
"
S="${WORKDIR}/${PN}-${COMMIT}"

LICENSE="GPL-2+ MS-TOU"
SLOT="0"
KEYWORDS="~amd64"

RESTRICT="bindist mirror test"

BDEPEND="app-arch/cabextract"

CONFIG_CHECK="SND CFG80211 INPUT_FF_MEMLESS USB POWER_SUPPLY LEDS_CLASS HID"
MODULES_KERNEL_MIN=5.13
PATCHES=(
)

src_unpack() {
	unpack ${P}.tar.gz

}

src_prepare() {
	cp "${FILESDIR}/Makefile" "${S}" || die
	default
}

src_compile() {
	local modlist=(
		xone-wired=kernel/drivers/input/joystick
		xone-dongle=kernel/drivers/input/joystick
		xone-gip=kernel/drivers/input/joystick
		xone-gip-gamepad=kernel/drivers/input/joystick
		xone-gip-headset=kernel/drivers/input/joystick
		xone-gip-chatpad=kernel/drivers/input/joystick
		xone-gip-madcatz-strat=kernel/drivers/input/joystick
		xone-gip-madcatz-glam=kernel/drivers/input/joystick
		xone-gip-pdp-jaguar=kernel/drivers/input/joystick
	)

	linux-mod-r1_src_compile
}

src_install() {
	linux-mod-r1_src_install

	einfo "Installing module blacklist"
	insinto /etc/modprobe.d/
	newins "${S}"/install/modprobe.conf xone-blacklist.conf

	einfo "Installing Microsoft binary firmware"
	insinto /lib/firmware/
    
	cabextract -F FW_ACC_00U.bin -d "${S}" "${DISTDIR}/${PN}-driver-${XONE_DRIVER_VERSION}.cab" > /dev/null \
		|| die "Failed to unpack driver"
	newins "${S}"/FW_ACC_00U.bin xow_dongle.bin

	cabextract -F FW_ACC_00U.bin -d "${S}" "${DISTDIR}/${PN}-driver-${XONE_045E_02E6_DRIVER_VERSION}.cab" > /dev/null \
		|| die "Failed to unpack driver"
	newins "${S}"/FW_ACC_00U.bin xow_dongle_045e_02e6.bin
}
