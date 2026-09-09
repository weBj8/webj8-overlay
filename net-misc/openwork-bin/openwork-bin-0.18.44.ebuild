# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop xdg

DESCRIPTION="Desktop client for OpenWork"
HOMEPAGE="https://openworklabs.com https://github.com/different-ai/openwork"
SRC_URI="
	amd64? ( https://github.com/different-ai/openwork/releases/download/v${PV}/openwork-linux-x64-${PV}.tar.gz
		-> ${P}-amd64.tar.gz )
	arm64? ( https://github.com/different-ai/openwork/releases/download/v${PV}/openwork-linux-arm64-${PV}.tar.gz
		-> ${P}-arm64.tar.gz )
"
S="${WORKDIR}/openwork-linux-${ARCH/amd64/x64}-${PV}"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm64"
RESTRICT="strip"

RDEPEND="
	app-accessibility/at-spi2-core:2
	app-crypt/libsecret
	dev-libs/expat
	dev-libs/glib:2
	dev-libs/nspr
	dev-libs/nss
	media-libs/alsa-lib
	media-libs/mesa
	net-print/cups
	sys-apps/dbus
	virtual/libudev
	x11-libs/cairo
	x11-libs/gtk+:3
	x11-libs/libX11
	x11-libs/libXcomposite
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libXrandr
	x11-libs/libxcb
	x11-libs/libxkbcommon
	x11-libs/pango
	x11-misc/xdg-utils
	x11-themes/hicolor-icon-theme
"

QA_PREBUILT="opt/openwork/*"

src_prepare() {
	default

	local node_arch=${ARCH/amd64/x64}
	local modules=resources/app.asar.unpacked/node_modules
	local prebuild
	for prebuild in "${modules}"/better-sqlite3/prebuilds/*.node; do
		if [[ ${prebuild##*/} != linux-${node_arch}.node ]]; then
			rm "${prebuild}" || die
		fi
	done
	for prebuild in "${modules}"/@lydell/node-pty-linux-*; do
		if [[ ${prebuild##*/} != node-pty-linux-${node_arch} ]]; then
			rm -r "${prebuild}" || die
		fi
	done
}

src_install() {
	local opt_dir="/opt/openwork"

	dodir "${opt_dir}"
	cp -a . "${ED}${opt_dir}/" || die
	dosym -r "${opt_dir}/openwork" /usr/bin/openwork

	newicon -s scalable resources/app-dist/openwork-logo-square.svg openwork.svg
	make_desktop_entry "openwork %U" OpenWork openwork "Development;Utility" \
		"MimeType=x-scheme-handler/openwork;"
}

pkg_postinst() {
	xdg_pkg_postinst
	elog "The upstream OpenWork build ships its own updater metadata."
	elog "Use Portage rather than the in-app updater to keep this package managed cleanly."
}

pkg_postrm() {
	xdg_pkg_postrm
}
