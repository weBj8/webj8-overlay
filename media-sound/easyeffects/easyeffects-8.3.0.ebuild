# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

KFMIN=6.10
QTMIN=6.8
inherit ecm optfeature toolchain-funcs xdg

DESCRIPTION="Limiter, auto volume and many other plugins for PipeWire applications"
HOMEPAGE="https://github.com/wwmm/easyeffects"
SRC_URI="https://github.com/wwmm/easyeffects/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"
# No real tests. ECM brings appstream test which isn't relevant downstream.
RESTRICT="test"

RDEPEND="
	dev-cpp/nlohmann_json
	dev-cpp/tbb:=
	dev-libs/kirigami-addons:6
	>=dev-qt/qtbase-${QTMIN}:6[dbus,gui,network,widgets]
	>=dev-qt/qtdeclarative-${QTMIN}:6
	>=dev-qt/qtgraphs-${QTMIN}:6
	>=kde-frameworks/kcolorscheme-${KFMIN}:6
	>=kde-frameworks/kconfig-${KFMIN}:6
	>=kde-frameworks/kconfigwidgets-${KFMIN}:6
	>=kde-frameworks/kcoreaddons-${KFMIN}:6
	>=kde-frameworks/ki18n-${KFMIN}:6
	>=kde-frameworks/kiconthemes-${KFMIN}:6
	>=kde-frameworks/kirigami-${KFMIN}:6
	>=kde-frameworks/qqc2-desktop-style-${KFMIN}:6
	media-libs/libbs2b
	>=media-libs/libebur128-1.2.6:=
	media-libs/libmysofa:=
	media-libs/libsndfile
	media-libs/libsoundtouch:=
	>=media-libs/lilv-0.24
	media-libs/rnnoise
	media-libs/speexdsp
	media-libs/webrtc-audio-processing:2
	>=media-libs/zita-convolver-3.0.0:=
	>=media-video/pipewire-1.0.6:=[sound-server]
	sci-libs/fftw:3.0=
	sci-libs/gsl:=
"
DEPEND="${RDEPEND}
	media-libs/ladspa-sdk
"
BDEPEND="
	dev-libs/appstream
	sys-devel/gettext
	virtual/pkgconfig
"

src_configure() {
	local libcxx=false
	[[ $(tc-get-cxx-stdlib) == "libc++" ]] && libcxx=true

	local mycmakeargs=(
		-DENABLE_LIBCPP_WORKAROUNDS=${libcxx}
		-DENABLE_LIBPORTAL=OFF
		-DENABLE_RNNOISE=ON
	)

	ecm_src_configure
}

pkg_postinst() {
	xdg_pkg_postinst

	optfeature_header "Install optional audio plugins:"
	optfeature "limiter, exciter, bass enhancer and others" media-plugins/calf
	optfeature "equalizer, compressor, delay, loudness" media-libs/lsp-plugins
	optfeature "maximizer" media-plugins/zam-plugins
	optfeature "bass loudness" media-plugins/mda-lv2
}
