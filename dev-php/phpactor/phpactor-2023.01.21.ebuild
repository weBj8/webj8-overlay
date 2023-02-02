# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="PHP completion, refactoring, introspection tool and language server"
HOMEPAGE="https://github.com/phpactor/phpactor"
SRC_URI="
	https://github.com/phpactor/phpactor/archive/refs/tags/${PV}.tar.gz -> ${P}.tar.gz
	https://media.wolf109909.top/download/eec4209a6f161bd829543dd8c0896e5a -> ${P}-vendor.tar.gz
"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

DEPEND="dev-lang/php[pcntl]"
RDEPEND="${DEPEND}"
BDEPEND="dev-php/composer"

RESTRICT="mirror"

src_compile() {
	mv "${WORKDIR}"/vendor "${S}" || die
	composer install --no-interaction --no-dev --optimize-autoloader --classmap-authoritative || die
}

src_install() {
	insinto /usr/lib/${PN}
	doins -r autoload bin doc ftplugin lib plugin templates tests vendor
	fperms +x /usr/lib/${PN}/bin/${PN}
	dosym -r /usr/lib/${PN}/bin/${PN} /usr/bin/${PN}
}
