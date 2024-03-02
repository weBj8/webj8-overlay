# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit unpacker xdg

DESCRIPTION="The desktop utility of the DSM Drive."
HOMEPAGE="https://www.synology.com"

SRC_URI="
	https://global.synologydownload.com/download/Utility/SynologyDriveClient/${PV/_p/-}/Ubuntu/Installer/synology-drive-client-${PV/*_p/}.x86_64.deb \
	-> ${P}.deb
"

LICENSE="synology"
SLOT="0"
KEYWORDS="-* ~amd64"

IUSE="gnome"
DEPEND="
	sys-libs/glibc
	gnome? ( gnome-base/nautilus )
"
RDEPEND="${DEPEND}"

S=${WORKDIR}

src_unpack(){
	:
}

src_install(){
	dodir /
	cd "${D}" || die
	unpacker "${DISTDIR}/${P}.deb"
}
