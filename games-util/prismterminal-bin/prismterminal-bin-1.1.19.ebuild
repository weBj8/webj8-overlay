EAPI=8

inherit unpacker xdg

DESCRIPTION="Keyboard configurator for PrismTerminal devices"
HOMEPAGE="https://github.com/Kagami-Studio/PrismTerminal-Release"
SRC_URI="https://github.com/Kagami-Studio/PrismTerminal-Release/releases/download/v${PV}/PrismTerminal-v${PV}-linux64.deb -> ${P}-amd64.deb"
S="${WORKDIR}"

LICENSE="all-rights-reserved"
SLOT="0"
KEYWORDS="-* ~amd64"
RESTRICT="bindist mirror strip"

BDEPEND="app-arch/dpkg"
RDEPEND="
	dev-libs/glib:2
	dev-libs/libayatana-appindicator
	dev-libs/openssl:=
	dev-libs/wayland
	media-libs/alsa-lib
	net-libs/libsoup:3.0
	net-libs/webkit-gtk:4.1
	sys-apps/dbus
	virtual/libudev:=
	x11-libs/cairo
	x11-libs/gdk-pixbuf:2
	x11-libs/gtk+:3
"

QA_PREBUILT="usr/bin/prismterminal-tauri"

src_unpack() {
	:
}

src_compile() {
	:
}

src_install() {
	unpack_deb "${DISTDIR}/${A}"
	cp -a usr "${ED}" || die
}
