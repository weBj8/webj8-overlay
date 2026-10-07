# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit xdg

DESCRIPTION="Open-source clean-room Acrobat alternative in pure Rust (prebuilt binary)"
HOMEPAGE="https://getartcraft.com/apps/printcraft https://github.com/storytold/printcraft"
SRC_URI="
	amd64? (
		https://github.com/storytold/printcraft/releases/download/v${PV}/printcraft-${PV}-linux-x86_64.tar.gz
	)
	arm64? (
		https://github.com/storytold/printcraft/releases/download/v${PV}/printcraft-${PV}-linux-aarch64.tar.gz
	)
"
MY_ARCH="${ARCH/amd64/x86_64}"
MY_ARCH="${MY_ARCH/arm64/aarch64}"
S="${WORKDIR}/printcraft-${PV}-linux-${MY_ARCH}"

LICENSE="|| ( Apache-2.0 MIT )"
SLOT="0"
KEYWORDS="-* ~amd64 ~arm64"

RDEPEND="
	!media-gfx/printcraft
	dev-libs/wayland
	media-libs/mesa
	media-libs/vulkan-loader
	x11-libs/libX11
	x11-libs/libxcb
	x11-libs/libxkbcommon
	x11-themes/hicolor-icon-theme
"

RESTRICT="mirror strip"
QA_PREBUILT="usr/bin/*"

src_install() {
	dobin bin/*
	insinto /usr
	doins -r share/applications share/icons share/metainfo share/mime
	dodoc share/doc/printcraft/README.md
}
