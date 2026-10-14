# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake edo

DESCRIPTION="Library for YUV conversion and scaling"
HOMEPAGE="https://chromium.googlesource.com/libyuv/libyuv"
# Upstream has no release tags. Use the commit date rather than the opaque
# third-party snapshot number used by older ebuilds (upstream version: 1974).
MY_COMMIT="58d817ed81e8fe8b06a58576d639cd56b19526d3"
SRC_URI="https://chromium.googlesource.com/libyuv/libyuv/+archive/${MY_COMMIT}.tar.gz -> ${P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="test"
RESTRICT="!test? ( test ) mirror"

RDEPEND="media-libs/libjpeg-turbo:0="
DEPEND="${RDEPEND}"
BDEPEND="test? ( dev-cpp/gtest )"

src_unpack() {
	mkdir "${S}" || die
	cd "${S}" || die
	unpack ${A}
}

src_prepare() {
	# Do not install static libraries; respect the multilib library directory.
	sed -i -e "/DESTINATION/s| lib| $(get_libdir)|g" \
		-e "/TARGETS \${ly_lib_static}/d" CMakeLists.txt \
		|| die "sed failed for CMakeLists.txt"

	cmake_src_prepare
}

src_configure() {
	local mycmakeargs=(
		-DUNIT_TEST="$(usex test)"
	)
	cmake_src_configure
}

src_test() {
	edo "${BUILD_DIR}"/libyuv_unittest
}

src_install() {
	cmake_src_install

	sed -e "s|%%VERSION%%|1974|" \
		-e "s|%%LIBDIR%%|$(get_libdir)|" \
		"${FILESDIR}"/libyuv.pc > "${T}"/libyuv.pc || die
	insinto /usr/"$(get_libdir)"/pkgconfig
	doins "${T}"/libyuv.pc
	insinto /usr/"$(get_libdir)"/cmake
	doins "${FILESDIR}"/libyuv-config.cmake
}
