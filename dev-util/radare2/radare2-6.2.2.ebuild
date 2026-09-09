# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit toolchain-funcs shell-completion

DESCRIPTION="unix-like reverse engineering framework and commandline tools"
HOMEPAGE="https://www.radare.org"

BINS_COMMIT=35b67ef6c274910348dfa17756a9837971e054d0
CAPSTONE_COMMIT=51360daf925e50d4da383cff2278107e6ffd8074
QJS_COMMIT=9d15fb60b67c45fd0de413bb49e48f8dacebac16
SDB_COMMIT=2.5.2

SRC_URI="
	mirror+https://github.com/radareorg/radare2/archive/${PV}.tar.gz -> ${P}.tar.gz
	mirror+https://github.com/capstone-engine/capstone/archive/${CAPSTONE_COMMIT}.tar.gz
		-> ${P}-capstone.tar.gz
	mirror+https://github.com/quickjs-ng/quickjs/archive/${QJS_COMMIT}.tar.gz
		-> ${P}-qjs.tar.gz
	mirror+https://github.com/radareorg/sdb/archive/${SDB_COMMIT}.tar.gz
		-> ${P}-sdb.tar.gz
	test? (
		https://github.com/radareorg/radare2-testbins/archive/${BINS_COMMIT}.tar.gz
			-> radare2-testbins-${BINS_COMMIT}.tar.gz
	)
"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~x86"
IUSE="ssl test"

# Need to audit licenses of the binaries used for testing
RESTRICT="fetch !test? ( test )"

RDEPEND="
	app-arch/lz4
	>=dev-libs/capstone-5.0_rc4:=
	dev-libs/libzip:=
	dev-libs/xxhash
	sys-apps/file
	virtual/zlib:=
	ssl? ( dev-libs/openssl:0= )
"
DEPEND="
	${RDEPEND}
	dev-util/gperf
"
BDEPEND="virtual/pkgconfig"

PATCHES=(
	"${FILESDIR}/${PN}-5.8.4-test.patch"
)

src_prepare() {
	default

	mv "${WORKDIR}/capstone-${CAPSTONE_COMMIT}" \
		subprojects/capstone-v5 || die
	mv "${WORKDIR}/quickjs-${QJS_COMMIT}" \
		subprojects/qjs || die
	mv "${WORKDIR}/sdb-${SDB_COMMIT}" subprojects/sdb || die

	if use test; then
		cp -r \
			"${WORKDIR}/radare2-testbins-${BINS_COMMIT}" \
			"${S}/test/bins" || die
		cp -r \
			"${WORKDIR}/radare2-testbins-${BINS_COMMIT}" \
			"${S}" || die
	fi

	# Fix hardcoded docdir for fortunes
	sed -i -e "/^#define R2_FORTUNES/s/radare2/$PF/" \
		libr/include/r_userconf.h.acr || die
}

src_configure() {
	tc-export CC AR LD OBJCOPY RANLIB
	export HOST_CC=${CC}

	econf \
		--with-syscapstone \
		--with-syslz4 \
		--with-sysmagic \
		--with-sysxxhash \
		--with-syszip \
		$(use_with ssl)
}

src_test() {
	ln -fs "${S}/binr/radare2/radare2" "${S}/binr/radare2/r2" || die
	LDFLAGS=""
	for i in "${S}"/libr/*; do
		if [[ -d ${i} ]]; then
			LDFLAGS+="-Wl,-rpath=${i} -L${i} "
			LD_LIBRARY_PATH+=":${i}"
		fi
	done
	export LDFLAGS LD_LIBRARY_PATH
	export PKG_CONFIG_PATH="${S}/pkgcfg"
	PATH="${S}/binr/radare2:${PATH}" emake -C test -k unit-tests || die
}

src_install() {
	default

	dozshcomp doc/zsh/_*

	newbashcomp doc/bash_autocompletion.sh "${PN}"
	bashcomp_alias "${PN}" rafind2 r2 rabin2 rasm2 radiff2

	local d
	for d in doc/*; do
		if [[ -d ${d} ]]; then
			rm -rfv "${d}" || die "failed to delete '${d}'"
		fi
	done

	docompress -x /usr/share/doc/${PF}/fortunes.{creepy,fun,nsfw,tips}

	keepdir "/usr/$(get_libdir)/radare2/${PV}" || die
}
