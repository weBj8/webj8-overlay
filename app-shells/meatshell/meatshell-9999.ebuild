# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

RUST_MIN_VER="1.88.0"

inherit cargo desktop git-r3 xdg

DESCRIPTION="Lightweight SSH, SFTP, and terminal client written in Rust and Slint"
HOMEPAGE="https://github.com/yituorou/meatshell"
EGIT_REPO_URI="https://github.com/yituorou/meatshell.git"

LICENSE="|| ( Apache-2.0 MIT ) CC-BY-4.0"
SLOT="0"

DEPEND="
	dev-libs/wayland
	media-libs/fontconfig
	media-libs/freetype
	media-libs/libglvnd
	virtual/libudev:=
	x11-libs/gtk+:3
	x11-libs/libxcb
	x11-libs/libxkbcommon
"
RDEPEND="
	${DEPEND}
	!app-shells/meatshell-bin
	x11-themes/hicolor-icon-theme
"
BDEPEND="
	dev-build/cmake
	virtual/pkgconfig
"

QA_FLAGS_IGNORED="usr/bin/meatshell"

pkg_setup() {
	rust_pkg_setup
}

src_unpack() {
	git-r3_src_unpack
	cargo_live_src_unpack
}

src_install() {
	dobin "$(cargo_target_dir)/meatshell"
	domenu assets/meatshell.desktop
	newicon -s 512 assets/icon@512.png meatshell.png
	dodoc CHANGELOG.md README.md README.en.md THIRD_PARTY_NOTICES.md
}
