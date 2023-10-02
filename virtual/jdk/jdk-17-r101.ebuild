# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Virtual for Java Development Kit (JDK)"
SLOT="17"
KEYWORDS="~amd64"
IUSE="headless-awt"

RDEPEND="|| (
		dev-java/openjdk-bin:${SLOT}[gentoo-vm(+),headless-awt=]
		dev-java/openjdk:${SLOT}[gentoo-vm(+),headless-awt=]
		dev-java/zulu-bin:${SLOT}[gentoo-vm(+),headless-awt=]
		dev-java/graalvm-bin:${SLOT}[gentoo-vm(+),headless-awt=]
		dev-java/zing-bin:${SLOT}[gentoo-vm(+),headless-awt=]
)"
