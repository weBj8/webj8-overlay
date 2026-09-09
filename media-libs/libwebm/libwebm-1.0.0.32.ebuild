# Copyright 2024-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake

DESCRIPTION="WebM video file parser"
HOMEPAGE="https://www.webmproject.org/"
SRC_URI="https://github.com/webmproject/${PN}/archive/refs/tags/${P}.tar.gz"
S="${WORKDIR}/${PN}-${P}"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~x86"
RESTRICT="mirror"
