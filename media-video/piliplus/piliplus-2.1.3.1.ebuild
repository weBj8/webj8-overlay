# Copyright 2026 Stllok <osustllok@gmail.com>
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop flag-o-matic xdg

FLUTTER_PV="3.47.2"
MY_PV="2.1.3+5315"

DESCRIPTION="Bilibili video client built with Flutter"
HOMEPAGE="https://github.com/bggRGjQaUbCoE/PiliPlus"
SRC_URI="
	https://github.com/bggRGjQaUbCoE/PiliPlus/archive/refs/tags/${PV}.tar.gz
		-> ${P}.tar.gz
	https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_PV}-stable.tar.xz
		-> flutter-${FLUTTER_PV}.tar.xz
"
S="${WORKDIR}/PiliPlus-${PV}"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="-* ~amd64"
RESTRICT="network-sandbox strip"

DEPEND="
	app-accessibility/at-spi2-core:2
	dev-libs/glib:2
	dev-libs/libayatana-appindicator
	media-libs/alsa-lib
	media-libs/fontconfig
	media-libs/harfbuzz
	media-libs/libepoxy
	media-video/mpv[libmpv]
	net-libs/webkit-gtk:4.1
	x11-libs/cairo
	x11-libs/gdk-pixbuf:2
	x11-libs/gtk+:3
	x11-libs/pango
"
RDEPEND="
	${DEPEND}
	!media-video/piliplus-bin
	dev-java/java-config
	x11-themes/hicolor-icon-theme
	virtual/jre
"
BDEPEND="
	app-arch/unzip
	dev-build/cmake
	dev-build/ninja
	dev-util/patchelf
	dev-vcs/git
	llvm-core/clang
	net-misc/curl
	virtual/pkgconfig
"

QA_PREBUILT="opt/piliplus/lib/libflutter_linux_gtk.so"

src_configure() {
	filter-flags \
		-fdevirtualize-at-ltrans \
		-fgraphite-identity \
		-floop-nest-optimize \
		-floop-strip-mine \
		-flto-partition=* \
		-fuse-linker-plugin \
		-Werror=lto-type-mismatch \
		-Werror=odr \
		-Wl,-flto=*
	filter-ldflags \
		-fuse-linker-plugin \
		-Wl,-flto=*
	filter-lto

	export CI=true
	export HOME="${WORKDIR}"
	export PUB_CACHE="${WORKDIR}/pub-cache"

	"${WORKDIR}/flutter/bin/flutter" config \
		--enable-linux-desktop \
		--no-analytics || die
	"${WORKDIR}/flutter/bin/flutter" pub get || die

	local patch
	local flutter_patches=(
		modal_barrier.patch
		text_selection.patch
		mouse_cursor.patch
		image_anim.patch
		layout_builder.patch
		navigation_drawer.patch
		popup_menu.patch
		fab.patch
		null_safety_for_selectable_region.patch
		selectable_region.patch
		editable_text.patch
		text_field.patch
		scroll_position.patch
		scrollable.patch
		scrollable_gesture.patch
		draggable_scrollable_sheet.patch
		scaffold.patch
		text.patch
		text_painter.patch
		sliver.patch
		refresh_indicator.patch
	)
	for patch in "${flutter_patches[@]}"; do
		git -C "${WORKDIR}/flutter" apply \
			"${S}/lib/scripts/${patch}" || die
	done

	rm -r "${PUB_CACHE}"/hosted/pub.dev/material_ui-* || die
	"${WORKDIR}/flutter/bin/flutter" pub get || die

	local material_dir=( "${PUB_CACHE}"/hosted/pub.dev/material_ui-* )
	local material_patches=(
		modal_barrier_material.patch
		navigation_drawer.patch
		popup_menu.patch
		fab.patch
		text_field.patch
		scaffold.patch
		refresh_indicator.patch
		tabs.patch
	)
	for patch in "${material_patches[@]}"; do
		git -C "${material_dir[0]}" apply \
			"${S}/lib/scripts/material/${patch}" || die
	done

	cat > pili_release.json <<-	EOF || die
	{"pili.name":"${MY_PV%+*}","pili.code":${MY_PV#*+},"pili.hash":"4d66b7b638c9cb9d533ffe95f23a56b822af90e2","pili.time":1788582982}
	EOF
}

src_compile() {
	export CI=true
	export HOME="${WORKDIR}"
	export PUB_CACHE="${WORKDIR}/pub-cache"

	"${WORKDIR}/flutter/bin/flutter" build linux \
		--release \
		--dart-define-from-file=pili_release.json \
		--no-pub || die
}

src_install() {
	local bundle="build/linux/x64/release/bundle"
	local opt_dir="/opt/piliplus"

	dodir "${opt_dir}"
	cp -R "${bundle}"/. "${ED}${opt_dir}/" || die
	fperms 0755 "${opt_dir}/piliplus"

	patchelf --set-rpath '$ORIGIN/lib' "${ED}${opt_dir}/piliplus" || die

	local lib
	for lib in "${ED}${opt_dir}"/lib/*.so; do
		patchelf --set-rpath '$ORIGIN' "${lib}" || die
	done

	cat > "${T}/piliplus" <<-	EOF || die
	#!/bin/sh
	JAVA_HOME=\$(java-config -O 2>/dev/null) || exit 1
	export LD_LIBRARY_PATH="${opt_dir}/lib:\${JAVA_HOME}/lib/server\${LD_LIBRARY_PATH:+:\${LD_LIBRARY_PATH}}"
	exec ${opt_dir}/piliplus "\$@"
	EOF
	dodir /usr/bin
	cp "${T}/piliplus" "${ED}/usr/bin/piliplus" || die
	fperms 0755 /usr/bin/piliplus

	newicon -s 512 assets/images/logo/logo.png piliplus.png

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
