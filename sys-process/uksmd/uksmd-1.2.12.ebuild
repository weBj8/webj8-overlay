# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v3

EAPI=8

inherit linux-info meson systemd

MY_COMMIT="87730a6ed35ddaf550a493434a288aa5a3e8822a"

DESCRIPTION="Userspace KSM helper daemon"
HOMEPAGE="https://github.com/CachyOS/uksmd"
SRC_URI="https://github.com/CachyOS/uksmd/archive/${MY_COMMIT}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86"

DEPEND="sys-libs/libcap-ng
	>=sys-process/procps-4:="
RDEPEND="${DEPEND}"

CONFIG_CHECK="~KSM"

S="${WORKDIR}/uksmd-${MY_COMMIT}"

src_install() {
	meson_src_install

	newinitd "${FILESDIR}/uksmd.init" uksmd
	systemd_dounit uksmd.service
}