# Copyright 2025 Stllok <osustllok@gmail.com>
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop xdg-utils

DESCRIPTION="Meowpad v2 配置器"
HOMEPAGE="https://desu.life/"
SRC_URI="
    https://assets.desu.life/device/app/resources/MeowpadConfiguratorForV2_v${PV}_linux.deb
    https://raw.githubusercontent.com/desu-life/MeowpadConfigurator/refs/heads/2.0-meowpad/LICENSE -> ${PN}-LICENSE.txt
"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

RDEPEND="
    dev-libs/glib:2
    dev-libs/openssl:0/1.1
    net-libs/webkit-gtk:4.1
    x11-libs/gtk+:3
    x11-libs/gdk-pixbuf:2
    dev-libs/libsoup:2.4
    sys-apps/systemd
    virtual/libc
    virtual/libgcc
    x11-themes/hicolor-icon-theme
"
DEPEND="
    ${RDEPEND}
    app-arch/ar
    app-arch/tar
"
BDEPEND="
    app-arch/ar
    app-arch/tar
"

S="${WORKDIR}"

QA_PREBUILT="usr/bin/*"

src_unpack() {
    cp "${DISTDIR}/MeowpadConfiguratorForV2_v${PV}_linux.deb" "${WORKDIR}/" || die
    cd "${WORKDIR}" || die
    ar x "MeowpadConfiguratorForV2_v${PV}_linux.deb" || die
    tar xf data.tar.gz || die
}

src_install() {
    # Install extracted files
    cp -r usr "${ED}/" || die

    # Install udev rule
    insinto /usr/lib/udev/rules.d/
    newins "${FILESDIR}/52-meowpad.rules" 52-meowpad.rules

    # Install license
    dodoc "${DISTDIR}/${PN}-LICENSE.txt"
    dosym "../../usr/share/doc/${PF}/${PN}-LICENSE.txt" "/usr/share/licenses/${PN}/LICENSE"

    # Remove unnecessary source directory
    rm -rf "${ED}/usr/src" || die
}

pkg_postinst() {
    xdg_icon_cache_update
    udev_reload
}

pkg_postrm() {
    xdg_icon_cache_update
    udev_reload
}