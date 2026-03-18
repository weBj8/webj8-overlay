# PROJECT KNOWLEDGE BASE

**Generated:** 2026-03-18T19:15:32+08:00
**Commit:** ceca1f8
**Branch:** main

## OVERVIEW
`webj8-overlay` is a Gentoo overlay repo, not an application repo. The main unit of change is usually a category/package directory with `*.ebuild`, `Manifest`, `metadata.xml`, and optional `files/` payloads.

Nearest `AGENTS.md` wins. Use this file for repo-wide routing; use child files for subtree-local conventions:
- `metadata/AGENTS.md`
- `app-emulation/AGENTS.md`
- `sys-kernel/AGENTS.md`

## STRUCTURE
```text
webj8-overlay/
├── metadata/            # overlay config + md5-cache entries
├── profiles/            # overlay identity (`repo_name`)
├── .github/workflows/   # PR validation + nvchecker automation
├── app-emulation/       # custom Wine variants and related payloads
├── sys-kernel/          # kernel sources, DKMS modules, kernel tooling
└── <category>/<pkg>/    # usual package root: ebuilds, Manifest, metadata.xml, files/
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| Overlay identity | `profiles/repo_name` | Canonical overlay name lives here (`webj8-overlay`). |
| Repo inheritance / manifest policy | `metadata/layout.conf` | `masters = gentoo`, `thin-manifests = true`, `sign-manifests = false`. |
| PR validation scope | `.github/workflows/build-on-pr.yml` | CI derives affected package dirs from changed `*/*/*.ebuild` paths. |
| Version-check automation | `.github/workflows/nvchecker.yml` | Runs Gentoo tooling plus `nvchecker` / `nvcmp`. |
| Overlay metadata rules | `metadata/AGENTS.md` | Use for `layout.conf` and `md5-cache` specifics. |
| Wine variant packaging | `app-emulation/AGENTS.md` | Use for `wine-osu` / `wine-tkg` patch-stack hotspots. |
| Kernel packages and tooling | `sys-kernel/AGENTS.md` | Use for sources, DKMS, and helper-package conventions. |
| Everything else | `<category>/<package>/` | Treat package root as the boundary unless a nearer AGENTS file exists. |

## CONVENTIONS
- This overlay inherits from `gentoo`; root-level policy lives in `metadata/layout.conf`.
- CI is path-driven. The PR workflow looks at changed `*/*/*.ebuild` files, derives package directories, and validates those directories.
- PR workflow ignores `.github/**` and `metadata/**`, so edits there do not automatically exercise the changed-ebuild path.
- `nvchecker` automation is part of repo maintenance and uses Gentoo commands (`egencache`, `eix-update`, `eix`) before running `nvchecker` / `nvcmp`.
- Docs are sparse. Within depth 4, only `README.md` and `sys-kernel/i915-sriov-dkms/README.user-guide.md` were found as human-oriented guidance.

## ANTI-PATTERNS (THIS PROJECT)
- Do not write AGENTS content as if this were an app, service, or monorepo with `src/` and test suites.
- Do not assume a repo-wide test harness exists; discovery found workflow validation surfaces, not a dedicated top-level test config.
- Do not treat `metadata/` as generic docs or scratch space; it contains overlay policy and structured cache data.
- Do not assume CI validates every file change equally; changed-ebuild paths are the main trigger surface.

## UNIQUE STYLES
- The meaningful structure is category/package depth, not language-module depth.
- Package-local helper payloads can live under `files/`, including shell scripts and Makefiles.
- Child AGENTS files should stay narrow: local conventions only, no restatement of root overlay basics.

## COMMANDS
```bash
git diff --name-only origin/main...HEAD -- '*/*/*.ebuild'
egencache
eix-update
eix <package>
nvchecker
nvcmp
```

## NOTES
- If work is centered in `metadata/`, `app-emulation/`, or `sys-kernel/`, read that subtree's AGENTS file before editing.
- For most other categories, the package directory itself is the best working boundary.
