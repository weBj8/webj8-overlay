# APP-EMULATION KNOWLEDGE BASE

## OVERVIEW
This subtree is dominated by custom Wine variants with heavy patch stacks, large USE matrices, and non-trivial unpack/prepare/configure logic.

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| Variant identity / upstream metadata | `wine-osu/metadata.xml`, `wine-tkg/metadata.xml` | Start here for package intent and maintainership. |
| `wine-osu` patch assembly | `wine-osu/wine-osu-*.ebuild` | `src_unpack` / `src_prepare` are the hotspot. |
| `wine-osu` payloads | `wine-osu/files/` | Recurring low-level fix themes: `noexecstack`, `unwind`, `rpath`, `lto-fixup`, MinGW precision fixes. |
| `wine-tkg` multilib / wrapper logic | `wine-tkg/wine-tkg-*.ebuild` | `src_configure` / `src_install` are the hotspot. |
| `wine-tkg` payloads | `wine-tkg/files/` | Check wrapper- and toolchain-adjacent patches first. |

## CONVENTIONS
- Both packages follow the same high-level shape: `metadata.xml` + slotted versioned ebuild + `files/` patch payloads.
- Both slot by full `${PV}` and rewrite `loader/wine.desktop` so the desktop entry launches the slotted variant name.
- Both use large Wine-style USE matrices, `RESTRICT="test"`, gecko/mono pinning, and sanity checks against `dlls/appwiz.cpl/addons.c`.
- Both rely on patch-stack handling plus Wine build tooling such as `eautoreconf` and `tools/make_requests`.
- `wine-osu` is the more custom patch-assembly package: Wine + Wine-Staging + external osu patch tarball + generated patch tree.
- `wine-tkg` is the more custom install/configure package: standalone source, multilib ordering, MinGW probing, `eselect-wine` wrappers, optional PE stripping.

## ANTI-PATTERNS
- Do not treat `wine-osu` and `wine-tkg` as the same upstream layout with cosmetic differences.
- Do not touch `wine-osu` `src_unpack` / `src_prepare` casually; patch-tree generation and exclude handling are central behavior.
- Do not touch `wine-tkg` `src_configure` / `src_install` casually; multilib order, wrapper creation, and stripping logic are central behavior.
- Do not ignore in-file `FIXME`, `TODO`, `TODO?`, and `UNSUPPORTED` comments; this subtree has concentrated maintenance hotspots.

## NOTES
- `wine-osu` carries the sharper maintenance warnings, including a manual patch replacement workaround and commented-out patch entries.
- `wine-tkg` carries more user-facing warnings around clang/wow64, LTO/runtime breakage, gcc-15/C23 breakage, and 32-bit/OpenGL/Vulkan expectations.
