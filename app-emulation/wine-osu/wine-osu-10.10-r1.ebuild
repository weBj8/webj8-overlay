# Copyright 2022-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..14} )
inherit edo optfeature python-any-r1 wine

WINE_GECKO=2.47.4
WINE_MONO=10.1.0
_PV=${PV/_/-}
WINE_P=wine-${_PV}
_P=wine-staging-${PV}
STAGING_COMMIT="c37f9f50912bd801e217ba81d2512feb7386f0d1"
WINE_COMMIT="885446556ce443b496e368b8f2c68807dcc7df0f"
OSU_PATCHES_TAGS="06-14-2025-88544655-c37f9f50"

if [[ ${PV} == *9999 ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://gitlab.winehq.org/wine/wine-staging.git"
	WINE_EGIT_REPO_URI="https://gitlab.winehq.org/wine/wine.git"
else
	(($(ver_cut 2))) && WINE_SDIR=$(ver_cut 1).x || WINE_SDIR=$(ver_cut 1).0
	SRC_URI="
		https://github.com/wine-mirror/wine/archive/${WINE_COMMIT}.tar.gz -> ${P}-${WINE_COMMIT}.tar.gz
		https://github.com/wine-staging/wine-staging/archive/${STAGING_COMMIT}.tar.gz -> ${P}-${STAGING_COMMIT}-staging.tar.gz
        https://github.com/whrvt/wine-osu-patches/archive/refs/tags/${OSU_PATCHES_TAGS}.tar.gz -> ${OSU_PATCHES_TAGS}-patch.tar.gz"
	KEYWORDS="-* ~amd64 ~x86"
fi

DESCRIPTION="Free implementation of Windows(tm) on Unix, with Wine-Staging patchset"
HOMEPAGE="
	https://wiki.winehq.org/Wine-Staging
	https://gitlab.winehq.org/wine/wine-staging/
"

S="${WORKDIR}/${WINE_P}"

LICENSE="
	LGPL-2.1+
	BSD BSD-2 IJG MIT OPENLDAP ZLIB gsm libpng2 libtiff
	|| ( WTFPL-2 public-domain )
"
SLOT="${PV}"
IUSE="
	+X +alsa bluetooth capi cups dbus dos llvm-libunwind +ffmpeg
	+fontconfig +gecko gphoto2 +gstreamer kerberos +mono netapi
	nls odbc opencl +opengl pcap perl +pulseaudio samba scanner
	+sdl selinux smartcard +ssl +truetype +udev +unwind usb v4l
	+vulkan +wayland +xcomposite +xinerama
"
# bug #551124 for truetype
# TODO: wow64 can be done without mingw if using clang (needs bug #912237)
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
		x11-libs/libXcursor[${WINE_USEDEP}]
		x11-libs/libXfixes[${WINE_USEDEP}]
		x11-libs/libXi[${WINE_USEDEP}]
		x11-libs/libXrandr[${WINE_USEDEP}]
		x11-libs/libXrender[${WINE_USEDEP}]
		x11-libs/libXxf86vm[${WINE_USEDEP}]
		xcomposite? ( x11-libs/libXcomposite[${WINE_USEDEP}] )
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
	capi? ( net-libs/libcapi:=[${WINE_USEDEP}] )
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
	unwind? (
		llvm-libunwind? ( llvm-runtimes/libunwind[${WINE_USEDEP}] )
		!llvm-libunwind? ( sys-libs/libunwind:=[${WINE_USEDEP}] )
	)
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
	sys-kernel/linux-headers
	X? ( x11-base/xorg-proto )
	bluetooth? ( net-wireless/bluez )
"
# gitapply.sh "can" work without git but that is hardly tested
# and known failing with some versions, so force real git
BDEPEND="
	${PYTHON_DEPS}
	dev-vcs/git
	sys-devel/bison
	sys-devel/flex
	virtual/pkgconfig
	nls? ( sys-devel/gettext )
	wayland? ( dev-util/wayland-scanner )
"

QA_CONFIG_IMPL_DECL_SKIP=(
	__clear_cache # unused on amd64+x86 (bug #900334)
	res_getservers # false positive
)
QA_TEXTRELS="usr/lib/*/wine/i386-unix/*.so" # uses -fno-PIC -Wl,-z,notext

PATCHES=(
	# "${FILESDIR}/lto-fixup.patch"
	"${FILESDIR}/makedep-fix.patch"
	"${FILESDIR}"/${PN}-7.17-noexecstack.patch
	"${FILESDIR}"/${PN}-7.20-unwind.patch
	"${FILESDIR}"/${PN}-8.13-rpath.patch
)

src_unpack() {
	if [[ ${PV} == 9999 ]]; then
		EGIT_CHECKOUT_DIR=${WORKDIR}/${P}
		git-r3_src_unpack

		# hack: use subshell to preserve state (including what git-r3 unpack
		# sets) for smart-live-rebuild as this is not the repo to look at
		(
			EGIT_COMMIT=$(<"${EGIT_CHECKOUT_DIR}"/staging/upstream-commit) || die
			EGIT_REPO_URI=${WINE_EGIT_REPO_URI}
			EGIT_CHECKOUT_DIR=${S}
			einfo "Fetching Wine commit matching the current patchset by default (${EGIT_COMMIT})"
			git-r3_src_unpack
		)
	else
		default
	fi

	# Currently don't have a better solution on this
	mkdir ${WORKDIR}/${WINE_P} || die
	mv ${WORKDIR}/wine-${WINE_COMMIT}/* ${WORKDIR}/${WINE_P} || die
	mkdir ${WORKDIR}/${_P} || die
	mv ${WORKDIR}/wine-staging-${STAGING_COMMIT}/* ${WORKDIR}/${_P} || die

	mkdir ${WORKDIR}/patch || die

	for dir in ./wine-osu-patches-${OSU_PATCHES_TAGS}/**; do
		mv "$dir" ${WORKDIR}/patch/. || die
	done
}

src_prepare() {
	local patchinstallargs=(
		--all
		--no-autoconf
		$(cat $WORKDIR/patch/staging-exclude || die)
		${MY_WINE_STAGING_CONF}
	)

	edo "${PYTHON}" ../${_P}/staging/patchinstall.py "${patchinstallargs[@]}" 

	# sanity check, bumping these has a history of oversights
	local geckomono=$(sed -En '/^#define (GECKO|MONO)_VER/{s/[^0-9.]//gp}' \
		dlls/appwiz.cpl/addons.c || die)
	if [[ ${WINE_GECKO}$'\n'${WINE_MONO} != "${geckomono}" ]]; then
		local gmfatal=
		[[ ${PV} == *9999 ]] && gmfatal=nonfatal
		${gmfatal} die -n "gecko/mono mismatch in ebuild, has: " ${geckomono} " (please file a bug)"
	fi

	default

	if tc-is-clang; then
		if use mingw; then
			# -mabi=ms was ignored by <clang:16 then turned error in :17
			# if used without --target *-windows, then gets used in install
			# phase despite USE=mingw, drop as a quick fix for now
			sed -i '/MSVCRTFLAGS=/s/-mabi=ms//' configure.ac || die
		else
			# fails in ./configure unless --enable-archs is passed, allow to
			# bypass with EXTRA_ECONF but is currently considered unsupported
			# (by Gentoo) as additional work is needed for (proper) support
			# note: also fails w/ :17, but unsure if safe to drop w/o mingw
			[[ ${EXTRA_ECONF} == *--enable-archs* ]] ||
				die "building ${PN} with clang is only supported with USE=mingw"
		fi
	fi

	# ensure .desktop calls this variant + slot
	sed -i "/^Exec=/s/wine /${P} /" loader/wine.desktop || die

	# datadir is not where wine-mono is installed, so prefixy alternate paths
	hprefixify -w /get_mono_path/ dlls/mscoree/metahost.c

	mapfile -t patchlist < <(find "${WORKDIR}/patch/" -type f -regex ".*\.patch" | LC_ALL=C sort -f) || die
	for patch in "${patchlist[@]}"; do
		eapply --ignore-whitespace -Np1 "$patch" || die
	done
	# always update for patches (including user's wrt #432348)
	eautoreconf
	tools/make_requests || die # perl
		if [ -e tools/make_specfiles ]; then
		tools/make_specfiles || die # perl
	fi
	# tip: if need more for user patches, with portage can e.g. do
	# echo "post_src_prepare() { tools/make_specfiles || die; }" \
	#     > /etc/portage/env/app-emulation/wine-staging
}

src_configure() {
	local wineconfargs=(
		$(use_enable gecko mshtml)
		$(use_enable mono mscoree)
		--disable-tests

		$(use_with X x)
		$(use_with alsa)
		$(use_with capi)
		$(use_with cups)
		$(use_with dbus)
		$(use_with ffmpeg)
		$(use_with fontconfig)
		$(use_with gphoto2 gphoto)
		$(use_with gstreamer)
		$(use_with kerberos gssapi)
		$(use_with kerberos krb5)
		$(use_with netapi)
		$(use_with nls gettext)
		$(use_with opencl)
		$(use_with opengl)
		--without-oss # media-sound/oss is not packaged (OSSv4)
		--without-coreaudio
		$(use_with pcap)
		$(use_with pulseaudio pulse)
		$(use_with scanner sane)
		$(use_with sdl)
		$(use_with smartcard pcsclite)
		$(use_with ssl gnutls)
		$(use_with truetype freetype)
		$(use_with udev)
		$(use_with unwind)
		$(use_with usb)
		$(use_with v4l v4l2)
		$(use_with vulkan)
		$(use_with wayland)
		$(use_with xcomposite)
		$(use_with xinerama)

		$(usev !bluetooth '
			ac_cv_header_bluetooth_bluetooth_h=no
			ac_cv_header_bluetooth_rfcomm_h=no
		')
		$(usev !odbc ac_cv_lib_soname_odbc=)
	)

	if use mingw; then
		use crossdev-mingw || PATH=${BROOT}/usr/lib/mingw64-toolchain/bin:${PATH}

		# CROSSCC was formerly recognized by wine, thus been using similar
		# variables (subject to change, esp. if ever make a mingw.eclass).
		# local mingwcc_amd64=${CROSSCC:-${CROSSCC_amd64:-x86_64-w64-mingw32-gcc}}
		# local mingwcc_x86=${CROSSCC:-${CROSSCC_x86:-i686-w64-mingw32-gcc}}
		# local -n mingwcc=mingwcc_$(usex abi_x86_64 amd64 x86)
		local mingwcc_amd64="clang"
		local mingwcc_x86="clang++"

		# # From https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=wine-osu-spectator-wow64
		local _fake_gnuc_flag="-fgnuc-version=5.99.99"
		local _polly_flags="-Xclang -load -Xclang /usr/lib/llvm/20/lib64/LLVMPolly.so -mllvm -polly -mllvm -polly-parallel -mllvm -polly-omp-backend=LLVM -mllvm -polly-vectorizer=stripmine"
    	_extra_native_flags+=" ${_polly_flags} -rtlib=compiler-rt -unwindlib=libgcc -static-libgcc"
		_extra_ld_flags+=" -rtlib=compiler-rt -unwindlib=libgcc -static-libgcc -fuse-ld=lld"
		_lto_flags+=" -flto=full -Wl,--lto-whole-program-visibility -D__LLD_LTO__"
		export wine_preloader_LDFLAGS="-fno-lto -fuse-ld=lld -Wl,--no-relax"
		export wine64_preloader_LDFLAGS="-fno-lto -fuse-ld=lld -Wl,--no-relax"
		export preloader_CFLAGS="-fno-lto -fuse-ld=lld -Wl,--no-relax"
  		_extra_native_flags+=" ${_fake_gnuc_flag} -mtls-dialect=gnu2"
		_extra_cross_flags+=" -fmsc-version=1933 -ffunction-sections -fdata-sections"
		_extra_crossld_flags+=" -Wl,/FILEALIGN:4096,/OPT:REF,/OPT:ICF,/HIGHENTROPYVA:NO"


  		_common_cflags="-march=native -mtune=native -pipe -O3 -mfpmath=sse -fno-strict-aliasing -fwrapv -fno-semantic-interposition \
                 -Wno-error=incompatible-pointer-types -Wno-error=implicit-function-declaration -w"

		export CPPFLAGS="-D_GNU_SOURCE -D_TIME_BITS=64 -D_FILE_OFFSET_BITS=64 -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=0 -DNDEBUG -D_NDEBUG"
  		_GCC_FLAGS="${_common_cflags:-} ${_lto_flags:-} ${_extra_native_flags:-} ${CPPFLAGS:-} -ffunction-sections -fdata-sections" # only for the non-mingw side
  		_CROSS_FLAGS="${_common_cflags:-} ${_extra_cross_flags:-} ${CPPFLAGS:-}" # only for the mingw side

  		_LD_FLAGS="${_GCC_FLAGS:-} ${_extra_ld_flags:-} -static-libgcc -Wl,-O2,--sort-common,--as-needed,--gc-sections"
  		_CROSS_LD_FLAGS="${_common_cflags:-} ${_extra_crossld_flags:-} ${CPPFLAGS:-}"

		conf+=(
			CC="ccache ${mingwcc_amd64}"
			CXX="ccache ${mingwcc_x86}"
  			x86_64_CC="ccache ${mingwcc_amd64}"
  			x86_64_CXX="ccache ${mingwcc_x86}"
  			i386_CC="ccache ${mingwcc_amd64}"
  			i386_CXX="ccache ${mingwcc_x86}"

			ac_cv_prog_x86_64_CC=" ${mingwcc_amd64}"
			ac_cv_prog_i386_CC=" ${mingwcc_x86}"

			CPPFLAGS="${CPPFLAGS}"

			CFLAGS="${_GCC_FLAGS} -std=gnu23"
			CXXFLAGS="${_GCC_FLAGS}"
			CROSSCFLAGS="${_CROSS_FLAGS} -std=gnu23"
			CROSSCXXFLAGS="${_CROSS_FLAGS}"

			LDFLAGS="${_LD_FLAGS}"
			CROSSLDFLAGS="${_CROSS_LD_FLAGS}"

			wine_preloader_LDFLAGS="${wine_preloader_LDFLAGS}"
			wine64_preloader_LDFLAGS="${wine64_preloader_LDFLAGS}"
			preloader_CFLAGS="${preloader_CFLAGS}"
		)
	fi

	# order matters with multilib: configure+compile 64->32, install 32->64
	local -i bits
	for bits in $(usev abi_x86_64 64) $(usev abi_x86_32 32); do
	(
		einfo "Configuring ${PN} for ${bits}bits in ${WORKDIR}/build${bits} ..."

		mkdir ../build${bits} || die
		cd ../build${bits} || die

		if (( bits == 64 )); then
			conf+=( --enable-win64 )
		elif use amd64; then
			conf+=(
				$(usev abi_x86_64 --with-wine64=../build64)
				TARGETFLAGS=-m32 # for widl
			)
			# _setup is optional, but use over Wine's auto-detect (+#472038)
			multilib_toolchain_setup x86
		fi

		ECONF_SOURCE=${S} econf "${conf[@]}"
	)
	done
}

src_compile() {
	use abi_x86_64 && emake -C ../build64 # do first
	use abi_x86_32 && emake -C ../build32
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

pkg_postrm() {
	if has_version -b app-eselect/eselect-wine; then
		eselect wine update --if-unset || die
	fi
}
