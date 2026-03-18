# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit unpacker xdg

DESCRIPTION="Desktop client for OpenWork"
HOMEPAGE="https://openworklabs.com https://github.com/different-ai/openwork"
SRC_URI="
	amd64? ( https://github.com/different-ai/openwork/releases/download/v${PV}/openwork-desktop-linux-amd64.deb -> ${P}-amd64.deb )
	arm64? ( https://github.com/different-ai/openwork/releases/download/v${PV}/openwork-desktop-linux-arm64.deb -> ${P}-arm64.deb )
"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm64"
RESTRICT="strip"

RDEPEND="
	!net-misc/openwork
	net-libs/webkit-gtk:4.1
	x11-libs/gtk+:3
	x11-themes/hicolor-icon-theme
"

S=${WORKDIR}

QA_PREBUILT="
	usr/bin/OpenWork-Dev
	usr/bin/chrome-devtools-mcp
	usr/bin/opencode
	usr/bin/opencode-router
	usr/bin/openwork-orchestrator
	usr/bin/openwork-server
"

src_unpack() {
	:
}

src_install() {
	dodir /
	cd "${ED}" || die
	unpacker "${DISTDIR}/${P}-${ARCH}.deb"

	sed -i \
		-e 's/^Categories=$/Categories=Development;Utility;/' \
		-e 's/^Exec=OpenWork-Dev$/Exec=openwork/' \
		-e 's/^Icon=OpenWork-Dev$/Icon=openwork/' \
		"${ED}/usr/share/applications/OpenWork.desktop" || die

	dosym -r /usr/bin/OpenWork-Dev /usr/bin/openwork
	dosym -r /usr/share/icons/hicolor/32x32/apps/OpenWork-Dev.png \
		/usr/share/icons/hicolor/32x32/apps/openwork.png
	dosym -r /usr/share/icons/hicolor/128x128/apps/OpenWork-Dev.png \
		/usr/share/icons/hicolor/128x128/apps/openwork.png
	dosym -r /usr/share/icons/hicolor/256x256@2/apps/OpenWork-Dev.png \
		/usr/share/icons/hicolor/256x256@2/apps/openwork.png
}

pkg_postinst() {
	xdg_pkg_postinst
	elog "The upstream OpenWork build ships its own updater metadata."
	elog "Use Portage rather than the in-app updater to keep this package managed cleanly."
}

pkg_postrm() {
	xdg_pkg_postrm
}
