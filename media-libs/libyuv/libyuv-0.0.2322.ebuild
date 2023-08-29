# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake edo

DESCRIPTION="Library for freeswitch yuv graphics manipulation"
HOMEPAGE="https://chromium.googlesource.com/libyuv/libyuv"
SRC_URI="https://sv.wolf109909.top:62500/f/7db6c054c8d8409199a7/?dl=1 -> ${P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="test"
RESTRICT="!test? ( test ) mirror"

RDEPEND="media-libs/libjpeg-turbo:0="
BDEPEND="test? ( dev-cpp/gtest )"

S="${WORKDIR}"

src_prepare() {
	# do not install static, fix libdir
	sed -i  -e "/DESTINATION/s| lib| $(get_libdir)|" \
		-e "/TARGETS \${ly_lib_static}/d" CMakeLists.txt \
		|| die "sed failed for CMakeLists.txt"

	cmake_src_prepare
}

src_configure() {
	local mycmakeargs=(
		-DTEST="$(usex test)"
	)

	cmake_src_configure
}

src_test() {
	edo "${S}"_build/libyuv_unittest
}

src_install() {
	cmake_src_install

	insinto /usr/"$(get_libdir)"/pkgconfig
	newins - libyuv.pc < <(sed -e "/Version/s|%%VERSION%%|${PV}|" \
				-e "/libdir/s|%%LIBDIR%%|"$(get_libdir)"|" \
				"${FILESDIR}"/libyuv.pc \
				|| die "sed failed for libyuv.pc.in" )
	insinto /usr/"$(get_libdir)"/cmake
	doins "${FILESDIR}"/libyuv-config.cmake
}
