# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop xdg

DESCRIPTION="Lightweight SSH, SFTP, and terminal client (prebuilt binary)"
HOMEPAGE="https://github.com/yituorou/meatshell"
SRC_URI="
	amd64? (
		https://github.com/yituorou/meatshell/releases/download/v${PV}/meatshell-v${PV}-linux-x86_64-glibc228.tar.gz
	)
	arm64? (
		https://github.com/yituorou/meatshell/releases/download/v${PV}/meatshell-v${PV}-linux-aarch64-glibc228.tar.gz
	)
"
MY_ARCH="${ARCH/amd64/x86_64}"
MY_ARCH="${MY_ARCH/arm64/aarch64}"
S="${WORKDIR}/meatshell-v${PV}-linux-${MY_ARCH}-glibc228"

LICENSE="|| ( Apache-2.0 MIT ) CC-BY-4.0"
SLOT="0"
KEYWORDS="-* ~amd64 ~arm64"

RDEPEND="
	!app-shells/meatshell
	media-libs/fontconfig
	media-libs/freetype
	x11-libs/gtk+:3
	x11-libs/libxkbcommon
	x11-themes/hicolor-icon-theme
"

RESTRICT="mirror strip"
QA_PREBUILT="usr/bin/meatshell"

src_install() {
	dobin meatshell
	domenu meatshell.desktop
	newicon -s 512 icon@512.png meatshell.png
	dodoc CHANGELOG.md README.md README.en.md THIRD_PARTY_NOTICES.md
}
