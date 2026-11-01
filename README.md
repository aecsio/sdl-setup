# sdl-setup

Builds and installs the latest stable releases of **SDL3**, **SDL3_image**,
**SDL3_ttf** and **SDL3_mixer** from source, so any build tool
(pkg-config, CMake, SwiftPM, cargo, ...) can find them.

## Quick start

```sh
./scripts/deps.sh --install   # Linux: SDL's video + audio build dependencies
./setup.sh                    # fetch → build → install → verify
```

`./setup.sh` installs into `/usr/local` (libraries in `/usr/local/lib`). On most
distros pkg-config, CMake, linkers and the runtime loader search it by default;
the scripts check this with `pkg-config` and `ldconfig` instead of assuming it,
and print the exports to add when it is not (e.g. Fedora). Only the install
step uses `sudo`, and only when `PREFIX` is not writable.

## What gets built

| Library    | Version pinned in `.env` | Notes |
|------------|--------------------------|-------|
| SDL3       | `SDL`                    | tests and examples off |
| SDL3_image | `SDL_IMAGE`              | bundled codecs, linked in; AVIF off (needs nasm) |
| SDL3_ttf   | `SDL_TTF`                | bundled freetype, harfbuzz, plutosvg |
| SDL3_mixer | `SDL_MIXER`              | bundled codecs (ogg/vorbis, opus, flac, mp3, ...), linked in |

All libraries are shared, built in `Release` mode, installed into `$PREFIX/lib`.
Bundled third-party code comes from each release's own submodules, at the exact
commits that release pins; submodules for disabled formats (SDL_image's JXL/AVIF
decoders, SDL_mixer's tremor) are not downloaded.

## Scripts

| Script                        | Does |
|-------------------------------|------|
| `setup.sh`                    | `fetch` → `build` → `install` → `verify` |
| `scripts/update-versions.sh`  | rewrites `.env` with the latest stable tags (`release-3.<even>.x`); review and commit the diff |
| `scripts/deps.sh [--install]` | prints (or installs) SDL's Linux build dependencies for Debian/Ubuntu, Fedora and Arch |
| `scripts/fetch.sh`            | shallow-clones each pinned tag and the submodules it uses into `src/`; resumes an interrupted fetch |
| `scripts/build.sh`            | builds into `build/`: SDL first, then the others against SDL's build tree |
| `scripts/install.sh`          | `cmake --install` into `PREFIX`, records the files in `$PREFIX/share/sdl-setup/`, runs `ldconfig` when needed |
| `scripts/verify.sh`           | checks pkg-config, runtime versions, real video/audio backends, runtime loading |
| `scripts/uninstall.sh`        | removes every file ever recorded in `$PREFIX/share/sdl-setup/`, including older versions |
| `scripts/env.sh`              | prints the exports for a non-system `PREFIX` |
| `scripts/clean.sh`            | removes `src/` and `build/` |

## Updating SDL

```sh
./scripts/update-versions.sh
git diff .env                 # review
./setup.sh
git commit -am "Update SDL releases"
```

## Settings

`.env` holds the pinned versions and the defaults. Override them per machine
in `.env.local` (gitignored) or in the environment; the environment wins,
then `.env.local`, then `.env`.

| Variable     | Default                             | |
|--------------|-------------------------------------|---|
| `PREFIX`     | `/usr/local`                        | install location |
| `BUILD_TYPE` | `Release`                           | CMake build type |
| `LIBS`       | `SDL SDL_image SDL_ttf SDL_mixer`   | libraries to build; SDL is always needed by the others |

### Installing without sudo

```sh
PREFIX=$HOME/.local ./setup.sh
eval "$(PREFIX=$HOME/.local ./scripts/env.sh)"   # add to your shell profile
```

A non-system prefix is not searched by default, so `env.sh` prints the
`PKG_CONFIG_PATH`, `CMAKE_PREFIX_PATH` and `LD_LIBRARY_PATH` (macOS:
`DYLD_LIBRARY_PATH`) exports that make it visible.

## Why verify?

SDL picks its video and audio backends at build time from the headers it finds.
Without the ALSA/PulseAudio/PipeWire headers it still builds, but only with
the `dummy` and `disk` audio drivers: SDL_mixer then loads and plays nothing.
`verify.sh` fails in that case, and when an older SDL elsewhere on the
system shadows the one just installed. It runs its test program without
`LD_LIBRARY_PATH`, so it also proves the libraries are found at runtime the
way a real consumer finds them.

## Uninstalling

```sh
./scripts/uninstall.sh
```

Every install is recorded in `$PREFIX/share/sdl-setup/<lib>.manifest` and merged
with earlier ones, so uninstalling also removes files left by older versions,
and it works after `clean.sh`.
