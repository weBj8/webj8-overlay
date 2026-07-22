# Copyright 2026 Stllok <osustllok@gmail.com>
# Distributed under the terms of the GNU General Public License v2

EAPI=8

MY_PV="${PV/_/-}"

inherit desktop unpacker xdg

DESCRIPTION="Client software for quality voice communication over the internet"
HOMEPAGE="https://www.teamspeak.com/"
SRC_URI="https://files.teamspeak-services.com/releases/client/${PV}/TeamSpeak3-Client-linux_amd64-${MY_PV}.run"
S=${WORKDIR}

LICENSE="Apache-2.0 BSD GPL-2 GPL-3 LGPL-2.1 LGPL-3 MIT openssl teamspeak3"
SLOT="3"
KEYWORDS="-* ~amd64"
IUSE="+alsa pulseaudio"
REQUIRED_USE="elibc_glibc || ( alsa pulseaudio )"
RESTRICT="bindist mirror strip"

RDEPEND="
	dev-libs/expat
	dev-libs/glib:2
	dev-libs/libevent:0/2.1-7
	dev-libs/libxml2-compat:2
	dev-libs/libxslt
	dev-libs/nspr
	dev-libs/nss
	media-libs/alsa-lib
	media-libs/fontconfig
	media-libs/freetype
	media-libs/lcms:2
	media-libs/libglvnd[X]
	sys-apps/dbus
	sys-apps/pciutils
	sys-devel/gcc:*
	virtual/zlib
	x11-libs/libICE
	x11-libs/libSM
	x11-libs/libX11
	x11-libs/libXcomposite
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libXi
	x11-libs/libXrandr
	x11-libs/libXrender
	x11-libs/libXtst
	x11-libs/libxcb
	x11-libs/libxkbcommon[X]
	x11-libs/xcb-util-image
	x11-libs/xcb-util-keysyms
	x11-libs/xcb-util-renderutil
	x11-libs/xcb-util-wm
	pulseaudio? ( media-libs/libpulse )
"

QA_PREBUILT="
	opt/teamspeak3-client/QtWebEngineProcess
	opt/teamspeak3-client/error_report
	opt/teamspeak3-client/libGL.so
	opt/teamspeak3-client/libQt5Core.so.5
	opt/teamspeak3-client/libQt5DBus.so.5
	opt/teamspeak3-client/libQt5Gui.so.5
	opt/teamspeak3-client/libQt5Network.so.5
	opt/teamspeak3-client/libQt5PrintSupport.so.5
	opt/teamspeak3-client/libQt5Qml.so.5
	opt/teamspeak3-client/libQt5QmlModels.so.5
	opt/teamspeak3-client/libQt5Quick.so.5
	opt/teamspeak3-client/libQt5QuickWidgets.so.5
	opt/teamspeak3-client/libQt5Sql.so.5
	opt/teamspeak3-client/libQt5Svg.so.5
	opt/teamspeak3-client/libQt5WebChannel.so.5
	opt/teamspeak3-client/libQt5WebEngineCore.so.5
	opt/teamspeak3-client/libQt5WebEngineWidgets.so.5
	opt/teamspeak3-client/libQt5WebSockets.so.5
	opt/teamspeak3-client/libQt5Widgets.so.5
	opt/teamspeak3-client/libQt5XcbQpa.so.5
	opt/teamspeak3-client/libc++.so.1
	opt/teamspeak3-client/libc++abi.so.1
	opt/teamspeak3-client/libcrypto.so.1.1
	opt/teamspeak3-client/libquazip.so
	opt/teamspeak3-client/libssl.so.1.1
	opt/teamspeak3-client/libunwind.so.1
	opt/teamspeak3-client/package_inst
	opt/teamspeak3-client/ts3client_linux_amd64
	opt/teamspeak3-client/iconengines/libqsvgicon.so
	opt/teamspeak3-client/imageformats/libqgif.so
	opt/teamspeak3-client/imageformats/libqjpeg.so
	opt/teamspeak3-client/imageformats/libqsvg.so
	opt/teamspeak3-client/platforms/libqxcb.so
	opt/teamspeak3-client/soundbackends/libalsa_linux_amd64.so
	opt/teamspeak3-client/sqldrivers/libqsqlite.so
	opt/teamspeak3-client/xcbglintegrations/libqxcb-egl-integration.so
	opt/teamspeak3-client/xcbglintegrations/libqxcb-glx-integration.so
"

src_prepare() {
	default

	rm imageformats/libqwebp.so || die
	rm platforms/libqwayland-{egl,generic,xcomposite-egl,xcomposite-glx}.so || die
	rm update || die
	sed -i \
		-e 's|^\./ts3client_linux_amd64 \$@$|exec ./ts3client_linux_amd64 "$@"|' \
		ts3client_runscript.sh || die

	if ! use alsa; then
		rm soundbackends/libalsa_linux_amd64.so || die
	fi
}

src_install() {
	local opt_dir="/opt/teamspeak3-client"

	dodir "${opt_dir}"
	cp -R . "${ED}${opt_dir}/" || die
	fperms 0755 \
		"${opt_dir}"/{QtWebEngineProcess,error_report,package_inst,ts3client_linux_amd64,ts3client_runscript.sh}

	cat > "${T}/ts3client" <<- EOF || die
	#!/bin/sh
	export QT_QPA_PLATFORM=xcb
	exec ${opt_dir}/ts3client_runscript.sh "\$@"
	EOF
	exeinto /opt/bin
	doexe "${T}/ts3client"

	newicon -s 128 styles/default/logo-128x128.png teamspeak3.png
	make_desktop_entry /opt/bin/ts3client "TeamSpeak 3 Client" teamspeak3 "Audio;AudioVideo;Network"
}

pkg_postinst() {
	xdg_pkg_postinst
	elog "Use Portage for TeamSpeak updates; the upstream updater is not installed."
}

pkg_postrm() {
	xdg_pkg_postrm
}
