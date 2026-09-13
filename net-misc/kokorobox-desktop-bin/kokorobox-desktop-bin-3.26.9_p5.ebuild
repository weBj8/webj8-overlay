# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop unpacker xdg

MY_PV=${PV/_p/-}
DESCRIPTION="Mihomo desktop client with subscription and application routing support"
HOMEPAGE="https://github.com/amamiyakokoro/KokoroBox-Desktop"
SRC_URI="
	amd64? ( https://github.com/amamiyakokoro/KokoroBox-Desktop/releases/download/${MY_PV}/kokorobox-desktop-linux-${MY_PV}-amd64.deb )
	arm64? ( https://github.com/amamiyakokoro/KokoroBox-Desktop/releases/download/${MY_PV}/kokorobox-desktop-linux-${MY_PV}-arm64.deb )
"
S=${WORKDIR}

LICENSE="GPL-3 MIT BSD LGPL-2.1"
SLOT="0"
KEYWORDS="-* ~amd64 ~arm64"
RESTRICT="strip"

RDEPEND="
	!net-misc/kokorobox-desktop
	app-accessibility/at-spi2-core:2
	app-crypt/libsecret
	dev-libs/expat
	dev-libs/glib:2
	dev-libs/nspr
	dev-libs/nss
	media-libs/alsa-lib
	media-libs/mesa
	net-firewall/iptables
	net-print/cups
	sys-apps/dbus
	sys-apps/iproute2
	sys-apps/util-linux
	sys-auth/polkit
	>=sys-libs/glibc-2.25
	virtual/libudev
	x11-libs/cairo
	x11-libs/gtk+:3
	x11-libs/libX11
	x11-libs/libXScrnSaver
	x11-libs/libXcomposite
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libXrandr
	x11-libs/libXtst
	x11-libs/libnotify
	x11-libs/libxcb
	x11-libs/libxkbcommon
	x11-libs/pango
	x11-misc/xdg-utils
	x11-themes/hicolor-icon-theme
"

QA_PREBUILT="opt/kokorobox/*"

src_prepare() {
	default
	sed -i \
		-e 's|^Exec=.*|Exec=kokorobox %U|' \
		-e "s|^Comment=.*|Comment=${DESCRIPTION}|" \
		-e 's|^Categories=.*|Categories=Network;|' \
		usr/share/applications/kokorobox.desktop || die
}

src_install() {
	dodir /opt
	cp -a opt/kokorobox "${ED}/opt/" || die
	dosym -r /opt/kokorobox/kokorobox /usr/bin/kokorobox

	domenu usr/share/applications/kokorobox.desktop
	insinto /usr/share/icons
	doins -r usr/share/icons/hicolor

	# Keep the Chromium sandbox, but do not make the proxy cores setuid.
	fperms 4755 /opt/kokorobox/chrome-sandbox
	dodoc opt/kokorobox/resources/THIRD_PARTY_NOTICES.md
}

pkg_postinst() {
	xdg_pkg_postinst
	elog "Use Portage for updates rather than the application's updater."
	elog "On amd64, the bundled Mihomo and service require an x86-64-v3 CPU."
	elog "Enable KokoroBox Service in the application for privileged routing and TUN."
	elog "Service setup requires a running polkit authentication agent."
	elog "Application routing requires kernel TPROXY, policy routing and cgroup support."
}
