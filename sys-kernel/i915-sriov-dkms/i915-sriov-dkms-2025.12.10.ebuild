# Copyright 2024-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit linux-mod-r1

DESCRIPTION="DKMS module for Linux i915 and xe drivers with SR-IOV support"
HOMEPAGE="https://github.com/strongtz/i915-sriov-dkms"

SRC_URI="https://github.com/strongtz/i915-sriov-dkms/archive/${PV}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/${P}"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

MODULES_KERNEL_MIN=6.12
MODULES_KERNEL_MAX=6.18

CONFIG_CHECK="DRM_I915 IOMMU_SUPPORT PCI_IOV"

src_compile() {
	MODULES_MAKEARGS+=(
		TARGET="${KV_FULL}"
	)
	local modlist=(
		intel_sriov_compat=compat
		i915=drivers/gpu/drm/i915
		kvmgt=drivers/gpu/drm/i915
		xe=drivers/gpu/drm/xe
	)
	linux-mod-r1_src_compile
}

src_install() {
	linux-mod-r1_src_install
	dodoc README.md COPYING
}

pkg_postinst() {
	elog ""
	elog "WARNING: This package is highly experimental and may cause system instability."
	elog ""
	elog "For SR-IOV functionality, this package must be installed on both host and guest systems."
	elog ""
	elog "Required kernel parameters:"
	elog "  intel_iommu=on"
	elog "  i915.enable_guc=3"
	elog "  i915.max_vfs=7"
	elog ""
	elog "If using Secure Boot, it must be disabled or modules must be manually signed."
	elog ""
	elog "Example configuration files are available in: /usr/share/doc/${PF}/"
	elog ""
}

pkg_prerm() {
	elog ""
	elog "Before removing, ensure you have removed any loaded modules:"
	elog "  # modprobe -r intel_sriov_compat i915 kvmgt xe"
	elog ""
	elog "You may need to update initramfs after removal if modules were added."
	elog ""
}
