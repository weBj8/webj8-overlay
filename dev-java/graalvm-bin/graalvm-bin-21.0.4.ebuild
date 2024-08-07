# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit java-vm-2 toolchain-funcs

SLOT="21"
MY_PV="21.0.4+8.1"

SRC_URI="https://download.oracle.com/graalvm/${SLOT}/archive/graalvm-jdk-${PV}_linux-x64_bin.tar.gz"

DESCRIPTION="Prebuilt Java JDK binaries provided by GraalVM"
HOMEPAGE="https://www.graalvm.org/"
LICENSE="GPL-2-with-classpath-exception"
KEYWORDS="~amd64"
IUSE="+alsa cups headless-awt selinux +source"

RDEPEND="
	>=sys-apps/baselayout-java-0.1.0-r1
	media-libs/fontconfig:1.0
	media-libs/freetype:2
	media-libs/harfbuzz
	elibc_glibc? ( >=sys-libs/glibc-2.2.5:* )
	elibc_musl? ( sys-libs/musl )
	sys-libs/zlib
	alsa? ( media-libs/alsa-lib )
	cups? ( net-print/cups )
	selinux? ( sec-policy/selinux-java )
	!headless-awt? (
		x11-libs/libX11
		x11-libs/libXext
		x11-libs/libXi
		x11-libs/libXrender
		x11-libs/libXtst
	)
	"

RESTRICT="preserve-libs splitdebug"
QA_PREBUILT="*"

S="${WORKDIR}/graalvm-jdk-${MY_PV}"

pkg_pretend() {
	if [[ "$(tc-is-softfloat)" != "no" ]]; then
		die "These binaries require a hardfloat system."
	fi
}

src_unpack() {
	default
}

src_install() {
	local dest="/opt/${P}"
	local ddest="${ED}/${dest#/}"

	# Not sure why they bundle this as it's commonly available and they
	# only do so on x86_64. It's needed by libfontmanager.so. IcedTea
	# also has an explicit dependency while Oracle seemingly dlopens it.
	rm -vf lib/libfreetype.so || die

	# prefer system copy # https://bugs.gentoo.org/776676
	rm -vf lib/libharfbuzz.so || die

	# Oracle and IcedTea have libjsoundalsa.so depending on
	# libasound.so.2 but AdoptOpenJDK only has libjsound.so. Weird.
	if ! use alsa ; then
		rm -v lib/libjsound.* || die
	fi

	if use headless-awt ; then
		rm -v lib/lib*{[jx]awt,splashscreen}* || die
	fi

	if ! use source ; then
		rm -v lib/src.zip || die
	fi

	rm -v lib/security/cacerts || die
	dosym -r /etc/ssl/certs/java/cacerts "${dest}"/lib/security/cacerts

	dodir "${dest}"
	cp -pPR * "${ddest}" || die

	# provide stable symlink
	dosym "${P}" "/opt/${PN}-${SLOT}"

	java-vm_install-env "${FILESDIR}"/${PN}.env.sh
	java-vm_set-pax-markings "${ddest}"
	java-vm_revdep-mask
	java-vm_sandbox-predict /dev/random /proc/self/coredump_filter
}

pkg_postinst() {
	java-vm-2_pkg_postinst
}
