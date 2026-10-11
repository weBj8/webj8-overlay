# Copyright 2026 Stllok <osustllok@gmail.com>
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop pax-utils xdg

DESCRIPTION="Firefox-based web browser focused on privacy and productivity (binary)"
HOMEPAGE="https://zen-browser.app https://github.com/zen-browser/desktop"
SRC_URI="
	amd64? (
		https://github.com/zen-browser/desktop/releases/download/${PV}/zen.linux-x86_64.tar.xz -> ${P}-x86_64.tar.xz
	)
	arm64? (
		https://github.com/zen-browser/desktop/releases/download/${PV}/zen.linux-aarch64.tar.xz -> ${P}-aarch64.tar.xz
	)
"
S="${WORKDIR}/zen"

LICENSE="MPL-2.0 GPL-2 LGPL-2.1"
SLOT="0"
KEYWORDS="-* ~amd64 ~arm64"
RESTRICT="strip"

RDEPEND="
	!www-client/zen
	|| (
		media-libs/libpulse
		media-sound/apulse
	)
	>=app-accessibility/at-spi2-core-2.46.0:2
	dev-libs/glib:2
	media-libs/alsa-lib
	media-libs/fontconfig
	media-libs/freetype
	media-video/ffmpeg
	sys-apps/dbus
	virtual/freedesktop-icon-theme
	x11-libs/cairo[X]
	x11-libs/gdk-pixbuf:2
	x11-libs/gtk+:3[X]
	x11-libs/libX11
	x11-libs/libXcomposite
	x11-libs/libXcursor
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libXi
	x11-libs/libXrandr
	x11-libs/libXrender
	x11-libs/libxcb
	x11-libs/pango
"

QA_PREBUILT="opt/zen/*"

src_install() {
	local dest=/opt/zen

	insinto ${dest}
	doins -r .
	# doins drops exec bits; restore them for ELF files and scripts
	find . -type f -perm -u+x -exec chmod 0755 "${ED}${dest}/{}" \; || die

	pax-mark m "${ED}${dest}"/{zen,zen-bin,plugin-container}

	# Updates come from Portage; this disables the in-app updater
	echo "This installation is managed by Gentoo's package manager." > "${ED}${dest}"/is-packaged-app || die

	insinto ${dest}/distribution
	newins - policies.json <<-EOF
	{ "policies": { "DisableAppUpdate": true } }
	EOF

	dosym -r ${dest}/zen /usr/bin/zen

	local size
	for size in 16 32 48 64 128; do
		newicon -s ${size} browser/chrome/icons/default/default${size}.png zen.png
	done

	make_desktop_entry "zen %u" "Zen Browser" zen "Network;WebBrowser;" \
		"MimeType=text/html;text/xml;application/xhtml+xml;application/pdf;x-scheme-handler/http;x-scheme-handler/https;\nStartupWMClass=zen"
}
