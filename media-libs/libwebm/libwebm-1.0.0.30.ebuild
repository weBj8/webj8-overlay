# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake

SRC_URI="
	https://github.com/webmproject/${PN}/archive/${P}.tar.gz
	https://aur.archlinux.org/cgit/aur.git/plain/cmake_install.patch?h=libwebm -> $PN.patch
"

KEYWORDS="~amd64 ~x86"

DESCRIPTION="WebM video file parser"
HOMEPAGE="https://www.webmproject.org/"

LICENSE="BSD"
SLOT="0"
RESTRICT="mirror"

S=$WORKDIR/$PN-$P

src_prepare() {
	eapply "${DISTDIR}/${PN}.patch"
	cmake_src_prepare
}
