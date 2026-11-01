# AGENTS.md

Context for coding agents working in this repository.

## Purpose

Build and install the latest **stable** releases of SDL3, SDL3_image, SDL3_ttf and
SDL3_mixer from source, so build tools can find them through pkg-config and CMake.

## Rules

1. **Versions live in `.env`.** Each library is pinned to a `release-X.Y.Z` tag.
   Stable SDL releases have an even minor version. Change versions only through
   `./scripts/update-versions.sh`, never by tracking a branch such as `main`.
2. **Build from source with the scripts.** Never suggest SDL packages from a system
   package manager (`libsdl3-dev`, ...). System packages that SDL needs to *build*
   (X11, Wayland, ALSA, PulseAudio, PipeWire headers) belong in `scripts/deps.sh`.
3. **Never modify downloaded sources.** `src/` and `build/` are generated and
   gitignored. Third-party code comes from each release's own submodules, at the
   commits that release pins; do not run the satellites' `external/download.sh`.
4. **Keep the flow:** `fetch.sh` → `build.sh` → `install.sh` → `verify.sh`, chained by
   `setup.sh`. Shared helpers and settings loading belong in `scripts/common.sh`.
   Per-library facts (pkg-config name, header, version function, CMake flags,
   unused submodules) live in the `lib_*` helpers and `ALL_LIBS` there; add a library
   by extending those, not by adding `case` blocks to other scripts.
5. **Build as a normal user.** Only `install.sh`/`uninstall.sh` may escalate, and only
   through `as_installer` when `PREFIX` is not writable. The one other exception is
   `deps.sh --install`, which installs system build dependencies with the package manager.
6. **Settings precedence:** environment > `.env.local` > `.env`.
7. **Check changes:** run `shellcheck -x -P scripts setup.sh scripts/*.sh` and keep it
   clean. After changing build options, run `./setup.sh` and make sure `verify.sh`
   passes, including the video and audio backend checks.

## Layout

- `setup.sh`: entry point
- `.env`: pinned versions and default settings
- `scripts/`: one script per step, plus `common.sh`
