# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake

DESCRIPTION="Qt based greeter for greetd"
HOMEPAGE="https://gitlab.com/marcusbritanicus/QtGreet"
SRC_URI="https://gitlab.com/marcusbritanicus/QtGreet/-/archive/v${PV}/QtGreet-v${PV}.tar.bz2"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="mirror"

DEPEND="
	dev-qt/qtcore:5
	dev-qt/qtwayland:5
	gui-libs/wlroots
	gui-libs/greetd
"
RDEPEND="${DEPEND}"
BDEPEND="kde-frameworks/extra-cmake-modules"

S="${WORKDIR}/QtGreet-v${PV}/src"
