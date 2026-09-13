# Copyright 2026 Stllok <osustllok@gmail.com>
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop xdg

MY_PV="${PV/_p/-}"
PNPM_PV="11.1.1"
ELECTRON_PV="44.3.0"
MIHOMO_PV="1.19.30"
SERVICE_PV="0.2.4"

DESCRIPTION="Mihomo proxy client built from its Electron/React application sources"
HOMEPAGE="https://github.com/amamiyakokoro/KokoroBox-Desktop"
SRC_URI="
	https://github.com/amamiyakokoro/KokoroBox-Desktop/archive/refs/tags/${MY_PV}.tar.gz -> ${P}.tar.gz
	https://registry.npmjs.org/pnpm/-/pnpm-${PNPM_PV}.tgz
	amd64? (
		https://github.com/electron/electron/releases/download/v${ELECTRON_PV}/electron-v${ELECTRON_PV}-linux-x64.zip
		https://github.com/MetaCubeX/mihomo/releases/download/v${MIHOMO_PV}/mihomo-linux-amd64-v3-v${MIHOMO_PV}.gz
		https://github.com/amamiyakokoro/kokorobox-service/releases/download/v${SERVICE_PV}/kokorobox-service-linux-amd64-v3 -> kokorobox-service-${SERVICE_PV}-linux-amd64-v3
	)
	arm64? (
		https://github.com/electron/electron/releases/download/v${ELECTRON_PV}/electron-v${ELECTRON_PV}-linux-arm64.zip
		https://github.com/MetaCubeX/mihomo/releases/download/v${MIHOMO_PV}/mihomo-linux-arm64-v${MIHOMO_PV}.gz
		https://github.com/amamiyakokoro/kokorobox-service/releases/download/v${SERVICE_PV}/kokorobox-service-linux-arm64 -> kokorobox-service-${SERVICE_PV}-linux-arm64
	)
"
S="${WORKDIR}/KokoroBox-Desktop-${MY_PV}"

LICENSE="GPL-3 MIT BSD"
SLOT="0"
KEYWORDS="~amd64 ~arm64"
# Upstream supplies no offline dependency bundle. Only the locked npm dependency
# installation uses the network; Electron and the Go helpers are in SRC_URI.
RESTRICT="network-sandbox"

RDEPEND="
	!net-misc/kokorobox-desktop-bin
	app-accessibility/at-spi2-core:2
	app-crypt/libsecret
	dev-libs/expat
	dev-libs/glib:2
	dev-libs/libayatana-appindicator
	dev-libs/nspr
	dev-libs/nss
	media-libs/alsa-lib
	media-libs/mesa
	net-firewall/iptables
	net-misc/iputils
	net-print/cups
	sys-apps/dbus
	sys-apps/iproute2
	sys-apps/util-linux
	sys-auth/polkit
	>=sys-libs/glibc-2.25
	virtual/libudev
	x11-libs/cairo
	x11-libs/gdk-pixbuf:2
	x11-libs/gtk+:3
	x11-libs/libdrm
	x11-libs/libnotify
	x11-libs/libX11
	x11-libs/libxcb
	x11-libs/libXcomposite
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libxkbcommon
	x11-libs/libXrandr
	x11-libs/libXScrnSaver
	x11-libs/libXtst
	x11-libs/pango
	x11-misc/xdg-utils
	x11-themes/hicolor-icon-theme
"
BDEPEND="
	app-arch/unzip
	>=net-libs/nodejs-22.18.0[npm]
"

# The application is compiled below, but Electron, kokorobox-native (including
# its traffic presenter), Mihomo and KokoroBox Service are upstream binaries.
QA_PREBUILT="opt/kokorobox/*"

src_unpack() {
	unpack "${P}.tar.gz" "pnpm-${PNPM_PV}.tgz"
	local electron_arch=x64 core_arch=amd64-v3
	if use arm64; then
		electron_arch=arm64
		core_arch=arm64
	fi
	unpack "mihomo-linux-${core_arch}-v${MIHOMO_PV}.gz"
	mkdir "${WORKDIR}/electron" || die
	cd "${WORKDIR}/electron" || die
	unpack "electron-v${ELECTRON_PV}-linux-${electron_arch}.zip"
}

src_prepare() {
	default
	# Upstream installs native dependencies for every release target. Retain
	# only the current host so foreign ELF/PE/Mach-O helpers are not packaged.
	sed -i -E '/^    - (win32|darwin|x64|arm64)$/d' pnpm-workspace.yaml || die
}

src_configure() {
	export HOME="${WORKDIR}"
	export XDG_CACHE_HOME="${WORKDIR}/.cache"
	export CI=true
	export KOKOROBOX_SYSTEM_CORE="${EPREFIX}/opt/kokorobox/resources/sidecar/mihomo"
	export KOKOROBOX_SYSTEM_SERVICE="${EPREFIX}/opt/kokorobox/resources/files/kokorobox-service"

	# Do not run prepare/postinstall: those fetch moving resources and Electron.
	# Keep the upstream lockfile and patched dependency definitions unchanged.
	node "${WORKDIR}/package/bin/pnpm.cjs" install \
		--frozen-lockfile --ignore-scripts \
		--store-dir "${WORKDIR}/pnpm-store" || die
}

src_compile() {
	local electron_arch=x64
	use arm64 && electron_arch=arm64
	# electron-builder's dependency collector invokes pnpm by name.
	chmod +x "${WORKDIR}/package/bin/pnpm.cjs" || die
	ln -sf pnpm.cjs "${WORKDIR}/package/bin/pnpm" || die
	export PATH="${WORKDIR}/package/bin:${PATH}"

	# Invoke the installed tool directly: pnpm exec can implicitly reinstall.
	node_modules/.bin/electron-vite build || die
	# This entry point removes upstream package-manager/service hooks in system
	# core mode, while retaining the architecture-specific traffic presenter.
	node scripts/package-linux.ts --dir "--${electron_arch}" \
		-c.electronDist="${WORKDIR}/electron" -c.npmRebuild=false || die
}

src_install() {
	local bundle=dist/linux-unpacked core_arch=amd64-v3
	if use arm64; then
		bundle=dist/linux-arm64-unpacked
		core_arch=arm64
	fi

	dodir /opt/kokorobox
	cp -a "${bundle}"/. "${ED}/opt/kokorobox/" || die
	# Chromium's sandbox is the only setuid helper; never setuid the cores.
	fperms 4755 /opt/kokorobox/chrome-sandbox

	exeinto /opt/kokorobox/resources/sidecar
	newexe "${WORKDIR}/mihomo-linux-${core_arch}-v${MIHOMO_PV}" mihomo
	exeinto /opt/kokorobox/resources/files
	newexe "${DISTDIR}/kokorobox-service-${SERVICE_PV}-linux-${core_arch}" kokorobox-service

	newbin "${FILESDIR}/kokorobox" kokorobox
	sed -i "s|@EPREFIX@|${EPREFIX}|g" "${ED}/usr/bin/kokorobox" || die
	newicon -s 512 build/icon.png kokorobox.png
	domenu "${FILESDIR}/kokorobox.desktop"
	dodoc README.md THIRD_PARTY_NOTICES.md "${FILESDIR}/README.gentoo"
}

pkg_postinst() {
	xdg_pkg_postinst
	elog "The app is source-built; Electron and native helpers are prebuilt."
	elog "On amd64, the bundled Mihomo and service require an x86-64-v3 CPU."
	elog "Only Chromium's sandbox is setuid; Mihomo and the service are not."
	elog "Use Portage for updates. See /usr/share/doc/${PF}/README.gentoo*"
	elog "for the build/network policy and opt-in service/TUN setup."
}
