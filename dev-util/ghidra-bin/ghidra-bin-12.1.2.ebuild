# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop xdg

MY_PN="${PN%-bin}"
MY_P="${MY_PN}_${PV}_PUBLIC"
PUBLIC_DATE="20260605"

DESCRIPTION="Software reverse engineering framework"
HOMEPAGE="https://github.com/NationalSecurityAgency/ghidra"
SRC_URI="https://github.com/NationalSecurityAgency/${MY_PN}/releases/download/Ghidra_${PV}_build/${MY_P}_${PUBLIC_DATE}.zip -> ${P}.zip"
S="${WORKDIR}/${MY_P}"

LICENSE="Apache-2.0 Apache-2.0-with-LLVM-exceptions BSD BSD-2 CC-BY-2.5 CNRI GPL-2 GPL-2-with-classpath-exception JDOM LGPL-2.1 LGPL-3 MIT MPL-2.0 POSTGRESQL PSF-2 public-domain ZLIB"
SLOT="0"
KEYWORDS="~amd64"

BDEPEND="app-arch/unzip"
RDEPEND="
	app-shells/bash
	>=virtual/jdk-21:*
	!dev-util/ghidra
"

RESTRICT="mirror strip"
QA_PREBUILT="opt/${MY_PN}/*"

src_install() {
	local dest="/opt/${MY_PN}"
	local ddest="${ED}/${dest#/}"

	dodir "${dest}"
	cp -a --no-preserve=ownership . "${ddest}" || die

	fperms +x \
		"${dest}/ghidraRun" \
		"${dest}/support/analyzeHeadless" \
		"${dest}/support/pyghidraRun"

	dosym -r "${dest}/ghidraRun" /usr/bin/ghidra
	dosym -r "${dest}/support/analyzeHeadless" /usr/bin/analyzeHeadless

	newicon -s 64 docs/GhidraClass/Beginner/Images/GhidraLogo64.png ghidra.png
	make_desktop_entry ghidra Ghidra ghidra "Development;Debugger;"
}
