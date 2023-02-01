# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-module

DESCRIPTION="Dancing visualizer of osu! maps and custom osu! client written in Go."
HOMEPAGE="https://github.com/Wieku/danser-go"
SRC_URI="
	https://github.com/Wieku/danser-go/archive/refs/tags/${PV}.tar.gz -> ${P}.tar.gz
	https://github.com/st0nie/gentoo-go-dep/releases/download/${PN}/${P}-deps.tar.xz
"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"

DEPEND="
	media-libs/libyuv
	media-video/ffmpeg
"
RDEPEND="${DEPEND}"
RESTRICT="mirror"

S=${WORKDIR}/danser-go-${PV}

src_compile() {
	ego build \
		-trimpath \
		-modcacherw \
		-mod=readonly \
		-ldflags "-s -w -X 'github.com/wieku/danser-go/build.VERSION=$PV'
			-X 'github.com/wieku/danser-go/build.Stream=Release'
			-X 'github.com/wieku/danser-go/build.DanserExec=danser'" \
				-buildmode=c-shared \
				-o danser-core.so \
				-v -x
	mv danser-core.so libdanser-core.so || die
	cc -o danser -I. cmain/main_danser.c -Wl,-rpath,. \
		-Wl,-rpath,/usr/lib/danser -L. -ldanser-core || die
	ego run tools/assets/assets.go ./
}

src_install() {
	insinto /usr/lib/danser/
	insopts -m0755
	doins libdanser-core.so libbass.so libbass_fx.so libbassmix.so assets.dpak danser
	dosym -r /usr/lib/danser/danser /usr/bin/danser
}
