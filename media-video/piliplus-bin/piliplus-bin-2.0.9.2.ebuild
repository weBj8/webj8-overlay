# Copyright 2026 Stllok <osustllok@gmail.com>
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop xdg

MY_PV="2.0.9+5051"
MY_PV_URI="${MY_PV/+/%2B}"

DESCRIPTION="Bilibili video client built with Flutter"
HOMEPAGE="https://github.com/bggRGjQaUbCoE/PiliPlus"
SRC_URI="https://github.com/bggRGjQaUbCoE/PiliPlus/releases/download/${PV}/PiliPlus_linux_${MY_PV_URI}_amd64.tar.gz -> ${P}-amd64.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="-* ~amd64"
RESTRICT="strip"

RDEPEND="
	!media-video/piliplus
	app-accessibility/at-spi2-core:2
	dev-libs/glib:2
	dev-libs/libayatana-appindicator
	dev-java/java-config
	media-libs/alsa-lib
	media-libs/fontconfig
	media-libs/harfbuzz
	media-libs/libepoxy
	media-video/mpv[libmpv]
	net-libs/webkit-gtk:4.1
	sys-libs/zlib
	x11-libs/cairo
	x11-libs/gdk-pixbuf:2
	x11-libs/gtk+:3
	x11-libs/pango
	x11-themes/hicolor-icon-theme
	virtual/jre
"
BDEPEND="dev-util/patchelf"

S=${WORKDIR}

QA_PREBUILT="
	opt/piliplus/lib/*.so
	opt/piliplus/piliplus
"

src_prepare() {
	default

	patchelf --set-rpath '$ORIGIN/lib' piliplus || die

	local lib
	for lib in lib/*.so; do
		patchelf --set-rpath '$ORIGIN' "${lib}" || die
	done
}

src_install() {
	local opt_dir="/opt/piliplus"

	dodir "${opt_dir}"
	cp -R data lib piliplus "${ED}${opt_dir}/" || die
	fperms 0755 "${opt_dir}/piliplus"

	cat > "${T}/piliplus" <<-	EOF || die
	#!/bin/sh
	JAVA_HOME=\$(java-config -O 2>/dev/null) || exit 1
	export LD_LIBRARY_PATH="${opt_dir}/lib:\${JAVA_HOME}/lib/server\${LD_LIBRARY_PATH:+:\${LD_LIBRARY_PATH}}"
	exec ${opt_dir}/piliplus "\$@"
	EOF
	dodir /usr/bin
	cp "${T}/piliplus" "${ED}/usr/bin/piliplus" || die
	fperms 0755 /usr/bin/piliplus

	newicon -s 512 data/flutter_assets/assets/images/logo/logo.png piliplus.png

	cat > "${T}/com.example.piliplus.desktop" <<-	EOF || die
	[Desktop Entry]
	Name=PiliPlus
	Comment=Bilibili video client
	Exec=piliplus
	Icon=piliplus
	Terminal=false
	Type=Application
	Categories=Video;AudioVideo;Player;
	StartupWMClass=com.example.piliplus
	EOF

	domenu "${T}/com.example.piliplus.desktop"
}

pkg_postinst() {
	xdg_pkg_postinst
	elog "Use Portage for PiliPlus updates; ignore upstream update prompts if present."
}

pkg_postrm() {
	xdg_pkg_postrm
}
