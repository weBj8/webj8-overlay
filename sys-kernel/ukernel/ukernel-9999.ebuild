# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

EGIT_REPO_URI="https://gitea.stllokserver.synology.me/ston/ukernel.git"
inherit git-r3

DESCRIPTION="A Bash script used to compile and update kernel on Gentoo Linux"
HOMEPAGE="https://gitea.stllokserver.synology.me/ston/ukernel"

LICENSE="GPL-3"
SLOT="0"

src_install(){
	dobin ukernel
	keepdir /etc/ukernel.conf.d/
	insinto /etc/
	newins ukernel.conf.example ukernel.conf
}
