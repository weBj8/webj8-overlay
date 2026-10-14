# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit unpacker xdg

DESCRIPTION="Desktop file synchronization client for Synology Drive"
HOMEPAGE="https://www.synology.com"

SRC_URI="
	https://global.synologydownload.com/download/Utility/SynologyDriveClient/${PV/_p/-}/Ubuntu/Installer/synology-drive-client-${PV/*_p/}.x86_64.deb \
	-> ${P}.deb
"

S=${WORKDIR}

LICENSE="synology"
SLOT="0"
KEYWORDS="-* ~amd64"
IUSE="gnome"
RESTRICT="strip"

DEPEND="
	dev-libs/glib:2
	sys-libs/glibc
	x11-libs/gtk+:2
	gnome? ( gnome-base/nautilus )
"
RDEPEND="${DEPEND}"

QA_PREBUILT="opt/Synology/* usr/lib/nautilus/extensions-*/*.so"

src_unpack() {
	:
}

src_install() {
	dodir /
	cd "${D}" || die
	unpacker "${DISTDIR}/${P}.deb"
}
