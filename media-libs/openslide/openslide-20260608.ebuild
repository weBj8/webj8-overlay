# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit meson

# Keep date-based versions so the 4.0.1 release upgrades the 20230904 snapshot.
MY_PV="4.0.1"
MY_P="${PN}-${MY_PV}"
DESCRIPTION="C library with simple interface to read virtual slides"
HOMEPAGE="https://openslide.org/"
SRC_URI="https://github.com/openslide/openslide/releases/download/v${MY_PV}/${MY_P}.tar.xz"
S="${WORKDIR}/${MY_P}"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="~amd64 ~arm64 ~loong"

DEPEND="
	>=dev-db/sqlite-3.14:3
	>=dev-libs/glib-2.56:2
	dev-libs/libxml2:2
	>=media-libs/libdicom-1.3.0
	media-libs/libjpeg-turbo:0=
	media-libs/libpng:0=
	>=media-libs/openjpeg-2.1.0:2=
	media-libs/tiff:0=
	app-arch/zstd:=
	virtual/zlib:=
	>=x11-libs/cairo-1.2
"
RDEPEND="${DEPEND}"
BDEPEND="virtual/pkgconfig"

src_configure() {
	local emesonargs=(
		-Ddoc=disabled
		-Dtest=disabled
	)
	meson_src_configure
}
