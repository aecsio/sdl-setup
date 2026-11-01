# shellcheck shell=bash
# Shared helpers, sourced by every script.
# Settings precedence: environment > .env.local > .env

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC2034 # used by the scripts that source this file
SRC_DIR="$ROOT/src"
BUILD_DIR="$ROOT/build"
# Install layout is pinned so every script agrees on it (GNUInstallDirs would
# pick lib64 on Fedora/openSUSE).
LIBDIR=lib

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarning:\033[0m %s\n' "$*" >&2; }
die() { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

# --- settings -----------------------------------------------------------------

# Load KEY=VALUE lines from a file without overriding variables that are already
# set. Lines starting with # are comments; values are taken literally.
load_env_file() {
    local file="$1" line key value
    [ -f "$file" ] || return 0
    while IFS= read -r line || [ -n "$line" ]; do
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"
        case "$line" in '' | '#'*) continue ;; esac
        line="${line#export }"
        key="${line%%=*}"
        value="${line#*=}"
        [[ "$line" == *=* && "$key" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || die "$file: cannot parse '$line'"
        value="${value%\"}"; value="${value#\"}"
        value="${value%\'}"; value="${value#\'}"
        if [ -z "${!key+x}" ]; then
            export "$key=$value"
        fi
    done < "$file"
}

load_env_file "$ROOT/.env.local"
load_env_file "$ROOT/.env"

: "${PREFIX:?PREFIX must be set in .env}"
: "${BUILD_TYPE:?BUILD_TYPE must be set in .env}"
: "${LIBS:?LIBS must be set in .env}"
PREFIX="${PREFIX%/}"

# --- libraries ----------------------------------------------------------------

# Every supported library, in build order: SDL first, the others build against it.
ALL_LIBS=(SDL SDL_image SDL_ttf SDL_mixer)

# .env variable holding a library's release tag: SDL_image -> SDL_IMAGE.
lib_var() { printf '%s\n' "$1" | tr '[:lower:]' '[:upper:]'; }

# pkg-config name: SDL -> sdl3, SDL_image -> sdl3-image.
lib_pc() { printf 'sdl3%s\n' "${1#SDL}" | tr '[:upper:]_' '[:lower:]-'; }

# Main header: SDL -> SDL3/SDL.h, SDL_image -> SDL3_image/SDL_image.h.
lib_header() { printf 'SDL3%s/%s.h\n' "${1#SDL}" "$1"; }

# Function returning the runtime version.
lib_version_fn() {
    case "$1" in
        SDL) echo SDL_GetVersion ;;
        SDL_image) echo IMG_Version ;;
        SDL_ttf) echo TTF_Version ;;
        SDL_mixer) echo MIX_Version ;;
    esac
}

# CMake options for a library: bundled third-party code, linked in.
lib_cmake_flags() {
    case "$1" in
        SDL) echo -DSDL_TESTS=OFF -DSDL_EXAMPLES=OFF ;;
        # AVIF needs nasm and is off; JXL is off by default.
        SDL_image) echo -DSDLIMAGE_VENDORED=ON -DSDLIMAGE_DEPS_SHARED=OFF -DSDLIMAGE_AVIF=OFF \
            -DSDLIMAGE_SAMPLES=OFF -DSDLIMAGE_TESTS=OFF ;;
        SDL_ttf) echo -DSDLTTF_VENDORED=ON -DSDLTTF_SAMPLES=OFF ;;
        SDL_mixer) echo -DSDLMIXER_VENDORED=ON -DSDLMIXER_DEPS_SHARED=OFF \
            -DSDLMIXER_TESTS=OFF -DSDLMIXER_EXAMPLES=OFF ;;
    esac
}

# Submodules not needed with the options above (they are large: libjxl alone is ~300 MB).
lib_unused_submodules() {
    case "$1" in
        SDL_image) echo external/libjxl external/libavif external/dav1d external/aom ;;
        SDL_mixer) echo external/tremor ;;
    esac
}

# Release tag pinned for a library, e.g. release-3.4.18.
tag_of() {
    local var
    var="$(lib_var "$1")"
    [ -n "${!var:-}" ] || die "$var is not set in .env"
    echo "${!var}"
}

# Version pinned for a library, e.g. 3.4.18.
version_of() {
    local tag
    tag="$(tag_of "$1")"
    echo "${tag#release-}"
}

repo_url() { echo "https://github.com/libsdl-org/$1.git"; }

# The libraries selected in LIBS, in build order.
ordered_libs() {
    local lib known known_lib
    for lib in $LIBS; do
        known=0
        for known_lib in "${ALL_LIBS[@]}"; do [ "$lib" = "$known_lib" ] && known=1; done
        [ "$known" = 1 ] || die "LIBS contains unknown library '$lib' (expected: ${ALL_LIBS[*]})"
    done
    for lib in "${ALL_LIBS[@]}"; do
        case " $LIBS " in *" $lib "*) echo "$lib" ;; esac
    done
}

# --- commands -----------------------------------------------------------------

# Run a command with its output in build/<log>.log; on failure show the tail and stop.
run_logged() {
    local name="$1" logfile="$BUILD_DIR/$1.log"
    shift
    mkdir -p "$BUILD_DIR"
    "$@" > "$logfile" 2>&1 || {
        tail -n 30 "$logfile"
        die "$name failed (full log: build/$name.log)"
    }
}

# Run a command with sudo when PREFIX is not writable by the current user.
as_installer() {
    local dir="$PREFIX"
    while [ ! -e "$dir" ]; do dir="$(dirname "$dir")"; done
    if [ -w "$dir" ]; then
        "$@"
    else
        command -v sudo >/dev/null || die "$PREFIX is not writable and sudo is not available"
        sudo "$@"
    fi
}

is_macos() { [ "$(uname -s)" = Darwin ]; }

# Directories the dynamic loader searches without LD_LIBRARY_PATH / DYLD_LIBRARY_PATH.
loader_dirs() {
    if is_macos; then
        printf '%s\n' "$HOME/lib" /usr/local/lib /usr/lib
    elif command -v ldconfig >/dev/null; then
        ldconfig -v -N -X 2>/dev/null | sed -n 's#^\(/[^:]*\):.*#\1#p'
    fi
}

# True when pkg-config and the loader both find PREFIX without extra setup.
# Asks the tools instead of assuming /usr/local is searched (it is not on Fedora).
is_system_prefix() {
    local pc_path
    pc_path="$(pkg-config --variable pc_path pkg-config 2>/dev/null || true)"
    case ":$pc_path:" in *":$PREFIX/$LIBDIR/pkgconfig:"*) ;; *) return 1 ;; esac
    loader_dirs | grep -qxF "$PREFIX/$LIBDIR"
}

# Refresh the loader cache after (un)installing into a system prefix on Linux.
refresh_loader_cache() {
    if ! is_macos && is_system_prefix && command -v ldconfig >/dev/null; then
        log "refreshing the shared library cache"
        as_installer ldconfig
    fi
}

# Durable record of everything installed into PREFIX, kept across builds,
# version upgrades and clean.sh.
# shellcheck disable=SC2034
MANIFEST_DIR="$PREFIX/share/sdl-setup"
