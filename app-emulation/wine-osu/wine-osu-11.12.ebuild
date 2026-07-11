# Copyright 2022-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

LLVM_COMPAT=( 22 )
PYTHON_COMPAT=( python3_{11..15} )
inherit edo flag-o-matic llvm-r2 optfeature python-any-r1 wine

WINE_GECKO=2.47.4
WINE_MONO=11.2.0
WINE_COMMIT="996020f410e7a1aa2dd6b44cf740854ea524d31a"
STAGING_COMMIT="bc50fb148ca22f8f328e7b75a7a2a7e145d0eec4"
OSU_PATCHES_COMMIT="a5fa1de7f67c79039326e162b735bb26241eba4a"
WINE_P="wine-${WINE_COMMIT}"
STAGING_P="wine-staging-${STAGING_COMMIT}"
OSU_PATCHES_P="wine-osu-patches-${OSU_PATCHES_COMMIT}"

DESCRIPTION="Free implementation of Windows(tm) on Unix, with Wine-Staging patchset"
HOMEPAGE="
	https://wiki.winehq.org/Wine-Staging
	https://gitlab.winehq.org/wine/wine-staging/
	https://github.com/NelloKudo/WineBuilder
	https://github.com/whrvt/wine-osu-patches
"
SRC_URI="
	https://github.com/wine-mirror/wine/archive/${WINE_COMMIT}.tar.gz -> ${P}-${WINE_COMMIT}.tar.gz
	https://github.com/wine-staging/wine-staging/archive/${STAGING_COMMIT}.tar.gz -> ${P}-${STAGING_COMMIT}-staging.tar.gz
	https://github.com/whrvt/wine-osu-patches/archive/${OSU_PATCHES_COMMIT}.tar.gz
		-> ${P}-${OSU_PATCHES_COMMIT}-patch.tar.gz
	https://raw.githubusercontent.com/KhronosGroup/Vulkan-Docs/v1.4.353/xml/vk.xml -> ${P}-vk.xml
	https://raw.githubusercontent.com/KhronosGroup/Vulkan-Docs/v1.4.353/xml/video.xml -> ${P}-video.xml
"
S=${WORKDIR}/${WINE_P}

LICENSE="
	LGPL-2.1+
	BSD BSD-2 IJG MIT OPENLDAP ZLIB gsm libpng2 libtiff
	|| ( WTFPL-2 public-domain )
"
SLOT="${PV}"
KEYWORDS="-* ~amd64 ~x86"
IUSE="
	+X +alsa bluetooth cups dbus dos +ffmpeg
	+fontconfig +gecko gphoto2 +gstreamer kerberos +mono netapi
	nls odbc opencl +opengl pcap perl +pulseaudio samba scanner
	+sdl selinux smartcard +ssl +truetype +udev usb v4l
	+vulkan +wayland +xinerama
"
REQUIRED_USE="
	X? ( truetype )
	bluetooth? ( dbus )
	opengl? ( || ( X wayland ) )
"

# tests are non-trivial to run, can hang easily, don't play well with
# sandbox, and several need real opengl/vulkan or network access
RESTRICT="test"

# `grep WINE_CHECK_SONAME configure.ac` + if not directly linked
WINE_DLOPEN_DEPEND="
	X? (
		x11-libs/libXcomposite[${WINE_USEDEP}]
		x11-libs/libXcursor[${WINE_USEDEP}]
		x11-libs/libXfixes[${WINE_USEDEP}]
		x11-libs/libXi[${WINE_USEDEP}]
		x11-libs/libXrandr[${WINE_USEDEP}]
		x11-libs/libXrender[${WINE_USEDEP}]
		x11-libs/libXxf86vm[${WINE_USEDEP}]
		xinerama? ( x11-libs/libXinerama[${WINE_USEDEP}] )
	)
	cups? ( net-print/cups[${WINE_USEDEP}] )
	dbus? ( sys-apps/dbus[${WINE_USEDEP}] )
	fontconfig? ( media-libs/fontconfig[${WINE_USEDEP}] )
	kerberos? ( virtual/krb5[${WINE_USEDEP}] )
	netapi? ( net-fs/samba[${WINE_USEDEP}] )
	odbc? ( dev-db/unixODBC[${WINE_USEDEP}] )
	opengl? ( media-libs/libglvnd[X?,${WINE_USEDEP}] )
	sdl? ( media-libs/libsdl2[haptic,joystick,${WINE_USEDEP}] )
	ssl? ( net-libs/gnutls:=[${WINE_USEDEP}] )
	truetype? ( media-libs/freetype[${WINE_USEDEP}] )
	v4l? ( media-libs/libv4l[${WINE_USEDEP}] )
	vulkan? ( media-libs/vulkan-loader[X?,wayland?,${WINE_USEDEP}] )
"
WINE_COMMON_DEPEND="
	${WINE_DLOPEN_DEPEND}
	X? (
		x11-libs/libX11[${WINE_USEDEP}]
		x11-libs/libXext[${WINE_USEDEP}]
	)
	alsa? ( media-libs/alsa-lib[${WINE_USEDEP}] )
	ffmpeg? ( media-video/ffmpeg:=[${WINE_USEDEP}] )
	gphoto2? ( media-libs/libgphoto2:=[${WINE_USEDEP}] )
	gstreamer? (
		dev-libs/glib:2[${WINE_USEDEP}]
		media-libs/gst-plugins-base:1.0[${WINE_USEDEP}]
		media-libs/gstreamer:1.0[${WINE_USEDEP}]
	)
	opencl? ( virtual/opencl[${WINE_USEDEP}] )
	pcap? ( net-libs/libpcap[${WINE_USEDEP}] )
	pulseaudio? ( media-libs/libpulse[${WINE_USEDEP}] )
	scanner? ( media-gfx/sane-backends[${WINE_USEDEP}] )
	smartcard? ( sys-apps/pcsc-lite[${WINE_USEDEP}] )
	udev? ( virtual/libudev:=[${WINE_USEDEP}] )
	usb? ( dev-libs/libusb:1[${WINE_USEDEP}] )
	wayland? (
		dev-libs/wayland[${WINE_USEDEP}]
		x11-libs/libxkbcommon[${WINE_USEDEP}]
	)
"
RDEPEND="
	${WINE_COMMON_DEPEND}
	app-emulation/wine-desktop-common
	dos? (
		|| (
			games-emulation/dosbox
			games-emulation/dosbox-staging
		)
	)
	gecko? (
		app-emulation/wine-gecko:${WINE_GECKO}[${WINE_USEDEP}]
		wow64? ( app-emulation/wine-gecko[abi_x86_32] )
	)
	gstreamer? ( media-plugins/gst-plugins-meta:1.0[${WINE_USEDEP}] )
	mono? ( app-emulation/wine-mono:${WINE_MONO} )
	perl? (
		dev-lang/perl
		dev-perl/XML-LibXML
	)
	samba? ( net-fs/samba[winbind] )
	selinux? ( sec-policy/selinux-wine )
"
DEPEND="
	${WINE_COMMON_DEPEND}
	>=sys-kernel/linux-headers-6.14
	X? ( x11-base/xorg-proto )
	bluetooth? ( net-wireless/bluez )
	opencl? ( dev-util/opencl-headers )
"
# gitapply.sh "can" work without git but that is hardly tested
# and known failing with some versions, so force real git
BDEPEND="
	${PYTHON_DEPS}
	$(llvm_gen_dep '
		llvm-core/clang:${LLVM_SLOT}=
		llvm-core/lld:${LLVM_SLOT}=
		llvm-core/llvm:${LLVM_SLOT}=
		llvm-core/polly:${LLVM_SLOT}=
	')
	dev-vcs/git
	sys-devel/bison
	sys-devel/flex
	virtual/pkgconfig
	amd64? ( dev-lang/nasm )
	nls? ( sys-devel/gettext )
	wayland? ( dev-util/wayland-scanner )
	x86? ( dev-lang/nasm )
"

QA_CONFIG_IMPL_DECL_SKIP=(
	__clear_cache # unused on amd64+x86 (bug #900334)
	res_getservers # false positive
)
QA_TEXTRELS="usr/lib/*/wine/i386-unix/*.so" # uses -fno-PIC -Wl,-z,notext
# intentionally ignored: https://gitlab.winehq.org/wine/wine/-/commit/433c2f8c06
QA_FLAGS_IGNORED="usr/lib/.*/wine/.*-unix/wine-preloader"

PATCHES=(
	"${FILESDIR}"/${PN}-7.17-noexecstack.patch
	"${FILESDIR}"/${PN}-8.13-rpath.patch
	"${FILESDIR}"/${PN}-11.12-winebus-dispatch-types.patch
	"${FILESDIR}"/${PN}-11.12-clang-full-lto.patch
)

pkg_setup() {
	python-any-r1_pkg_setup
	llvm-r2_pkg_setup

	local llvm_bin
	llvm_bin=$(get_llvm_prefix -b)/bin
	export CC=${llvm_bin}/clang
	export CXX=${llvm_bin}/clang++
	export AR=${llvm_bin}/llvm-ar
	export NM=${llvm_bin}/llvm-nm
	export RANLIB=${llvm_bin}/llvm-ranlib
}

src_prepare() {
	local patch_root=${WORKDIR}/${OSU_PATCHES_P}
	local patchinstallargs=(
		--all
		--no-autoconf
		${MY_WINE_STAGING_CONF}
	)

	edo "${PYTHON}" "../${STAGING_P}/staging/patchinstall.py" "${patchinstallargs[@]}"

	local patchlist patch
	mapfile -d '' -t patchlist < <(
		find "${patch_root}" -type f -name '*.patch' -print0 | LC_ALL=C sort -z -f
	) || die
	[[ ${#patchlist[@]} -eq 169 ]] ||
		die "Expected 169 osu! patches, found ${#patchlist[@]}"
	for patch in "${patchlist[@]}"; do
		eapply --ignore-whitespace -Np1 "${patch}"
	done

	edo "${PYTHON}" dlls/winevulkan/make_vulkan \
		--xml "${DISTDIR}/${P}-vk.xml" \
		--video-xml "${DISTDIR}/${P}-video.xml"

	# The external patch stack may add spec changes not covered by the eclass.
	if [[ -e tools/make_specfiles ]]; then
		tools/make_specfiles || die
	fi

	wine_src_prepare
}

src_configure() {
	local polly_lib
	polly_lib=$(get_llvm_prefix -b)/$(get_libdir)/LLVMPolly.so
	[[ -r ${polly_lib} ]] || die "Polly plugin not found: ${polly_lib}"

	local native_cflags="-O3 -pipe -fno-strict-aliasing -fwrapv"
	native_cflags+=" -flto=full -fpass-plugin=${polly_lib} -mllvm -polly -D__LLD_LTO__"
	local native_cxxflags=${native_cflags}
	local native_ldflags="-flto=full -fuse-ld=lld -Wl,--lto-whole-program-visibility"

	test-flag-CC ${native_cflags} || die "Clang does not accept native C LTO/Polly flags"
	test-flag-CXX ${native_cxxflags} || die "Clang does not accept native C++ LTO/Polly flags"
	( LDFLAGS=${native_ldflags}; test-flag-CCLD ${native_cflags} ${native_ldflags} ) ||
		die "Clang/LLD cannot link with native LTO/Polly flags"

	local wineconfargs=(
		$(use_enable gecko mshtml)
		$(use_enable mono mscoree)
		--disable-tests

		$(use_with X x)
		$(use_with alsa)
		--without-capi #977907
		$(use_with cups)
		$(use_with dbus)
		$(use_with ffmpeg)
		$(use_with fontconfig)
		$(use_with gphoto2 gphoto)
		$(use_with gstreamer)
		--without-hwloc # currently only used on FreeBSD
		$(use_with kerberos gssapi)
		$(use_with kerberos krb5)
		$(use_with netapi)
		$(use_with nls gettext)
		$(use_with opencl)
		$(use_with opengl)
		--without-oss # media-sound/oss is not packaged (OSSv4)
		$(use_with pcap)
		$(use_with pulseaudio pulse)
		$(use_with scanner sane)
		$(use_with sdl)
		$(use_with smartcard pcsclite)
		$(use_with ssl gnutls)
		$(use_with truetype freetype)
		$(use_with udev)
		$(use_with usb)
		$(use_with v4l v4l2)
		$(use_with vulkan)
		$(use_with wayland)
		$(use_with xinerama)

		$(usev !bluetooth '
			ac_cv_header_bluetooth_bluetooth_h=no
			ac_cv_header_bluetooth_rfcomm_h=no
		')
		$(usev !odbc ac_cv_lib_soname_odbc=)

		"CFLAGS=${native_cflags}"
		"CXXFLAGS=${native_cxxflags}"
		"LDFLAGS=${native_ldflags}"
	)

	wine_src_configure
}

src_install() {
	use perl || local WINE_SKIP_INSTALL=(
		${WINE_DATADIR}/man/man1/wine{dump,maker}.1
		${WINE_PREFIX}/bin/{function_grep.pl,wine{dump,maker}}
	)

	wine_src_install

	dodoc ANNOUNCE* AUTHORS README* documentation/README*
}

pkg_postinst() {
	wine_pkg_postinst

	optfeature "/dev/hidraw* access used for *some* controllers (e.g. DualShock4)" \
		games-util/game-device-udev-rules
}
