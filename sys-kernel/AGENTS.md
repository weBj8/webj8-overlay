# SYS-KERNEL KNOWLEDGE BASE

## OVERVIEW
`sys-kernel/` mixes patched kernel sources, DKMS modules, power/telemetry helpers, and kernel-maintenance tooling; not every package here is a kernel tree.

## STRUCTURE
```text
sys-kernel/
├── cachyos-sources/   # patched kernel sources
├── i915-sriov-dkms/   # DKMS module + package-local guide
├── ukernel/           # kernel helper utility + config scaffold
└── ...                # settings / telemetry / support packages
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| Package mix | `sys-kernel/*/` | Current tracked dirs include `cachyos-settings`, `cachyos-sources`, `i915-sriov-dkms`, `modprobed-db`, `ukernel`, `zenpower3`. |
| Experimental DKMS package | `i915-sriov-dkms/README.user-guide.md` + ebuild | Read both; package behavior includes operational guidance. |
| Patched kernel sources | `cachyos-sources/cachyos-sources-*.ebuild` | Large USE-controlled patch/config surface plus disk checks. |
| Kernel helper tooling | `ukernel/ukernel-*.ebuild` | Installs a Bash utility and config scaffolding, not a kernel build. |

## CONVENTIONS
- This subtree mixes several package types: sources, out-of-tree modules, and helper utilities.
- Package-local docs and installed config examples are part of the contract here, not just supplemental text.
- `i915-sriov-dkms` is explicitly experimental, kernel-version-bounded, and guarded by `CONFIG_CHECK`; its postinst/prerm messaging is part of expected behavior.
- `cachyos-sources` is a heavily customized sources package with external patch/config tarballs and many USE-gated patch paths.
- `ukernel` is operational tooling: it installs `/etc/ukernel.conf` from an example file and maintains `/etc/ukernel.conf.d/`.

## ANTI-PATTERNS
- Do not assume every package under `sys-kernel/` is a kernel sources package.
- Do not skip package-local docs when they exist; `i915-sriov-dkms` ships a user guide for a reason.
- Do not strip kernel bounds, config checks, or strong post-install guidance from `i915-sriov-dkms` without replacing the operational contract.
- Do not treat `ukernel` like a passive metadata package; config scaffolding is part of its behavior.

## NOTES
- If you are changing `cachyos-sources`, inspect the USE-controlled patch matrix before touching patch or config flow.
- If you are changing `i915-sriov-dkms`, account for supported kernel range and documented setup/troubleshooting steps.
