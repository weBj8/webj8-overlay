# Copyright 2026 Stllok <osustllok@gmail.com>
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit unpacker xdg

DESCRIPTION="Free and open source instant messaging and VoIP chat app"
HOMEPAGE="https://fluxer.app https://github.com/fluxerapp/fluxer"
SRC_URI="https://api.fluxer.app/dl/desktop/stable/linux/x64/${PV}/deb -> ${P}-amd64.deb"

LICENSE="AGPL-3"
SLOT="0"
KEYWORDS="-* ~amd64"
RESTRICT="strip"

RDEPEND="
	app-accessibility/at-spi2-core:2
	app-crypt/libsecret
	dev-libs/expat
	dev-libs/glib:2
	dev-libs/nss
	media-libs/alsa-lib
	media-libs/mesa
	net-print/cups
	sys-apps/dbus
	sys-apps/util-linux
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
	x11-libs/libXt
	x11-libs/libXtst
	x11-libs/libxcb
	x11-libs/libxkbcommon
	x11-misc/xdg-utils
	x11-themes/hicolor-icon-theme
"

S=${WORKDIR}

QA_PREBUILT="
	opt/Fluxer/*
	opt/Fluxer/resources/app.asar.unpacked/node_modules/@electron-webauthn/native-linux-x64-gnu/*.node
	opt/Fluxer/resources/app.asar.unpacked/node_modules/electron-webauthn-mac/native/*.node
	opt/Fluxer/resources/app.asar.unpacked/node_modules/node-mac-permissions/build/Release/*.node
	opt/Fluxer/resources/app.asar.unpacked/node_modules/uiohook-napi/prebuilds/*/*.node
"

src_unpack() {
	:
}

src_install() {
	dodir /
	cd "${ED}" || die
	unpacker "${DISTDIR}/${P}-amd64.deb"

	sed -i \
		-e 's|^Exec=/opt/Fluxer/fluxer %U$|Exec=fluxer %U|' \
		-e 's|^Comment=Fluxer$|Comment=Instant messaging and VoIP client|' \
		-e 's|^MimeType=.*$|MimeType=x-scheme-handler/fluxer;|' \
		-e 's|^Categories=.*$|Categories=Network;InstantMessaging;Chat;|' \
		"${ED}/usr/share/applications/fluxer.desktop" || die

	dosym -r /opt/Fluxer/fluxer /usr/bin/fluxer

	if [[ -f ${ED}/usr/share/doc/fluxer-app/changelog.gz ]]; then
		gunzip -c "${ED}/usr/share/doc/fluxer-app/changelog.gz" > "${T}/changelog" || die
		dodoc "${T}/changelog"
		rm -r "${ED}/usr/share/doc/fluxer-app" || die
	fi
}

pkg_postinst() {
	xdg_pkg_postinst
	if ! { [[ -L /proc/self/ns/user ]] && unshare --user true >/dev/null 2>&1; }; then
		elog "Fluxer's Electron sandbox may need kernel user namespaces enabled."
	fi
	elog "Use Portage for Fluxer updates; ignore upstream auto-update prompts if present."
}

pkg_postrm() {
	xdg_pkg_postrm
}
