# shellcheck shell=bash
# Shared helpers, sourced by every script.
# Settings precedence: environment > .env.local > .env

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC2034 # used by the scripts that source this file
SRC_DIR="$ROOT/src"
# shellcheck disable=SC2034
BUILD_DIR="$ROOT/build"

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarning:\033[0m %s\n' "$*" >&2; }
die() { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

# Load KEY=VALUE lines from a file without overriding variables that are already set.
load_env_file() {
    local file="$1" line key value
    [ -f "$file" ] || return 0
    while IFS= read -r line || [ -n "$line" ]; do
        line="${line%%#*}"
        line="$(printf '%s' "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
        [ -n "$line" ] || continue
        case "$line" in *=*) ;; *) continue ;; esac
        key="${line%%=*}"
        value="${line#*=}"
        value="${value%\"}"; value="${value#\"}"
        value="${value%\'}"; value="${value#\'}"
        if [ -z "${!key+x}" ]; then
            export "$key=$value"
        fi
    done < "$file"
}

load_env_file "$ROOT/.env.local"
load_env_file "$ROOT/.env"

: "${PREFIX:=/usr/local}"
: "${BUILD_TYPE:=Release}"
: "${LIBS:=SDL SDL_image SDL_ttf SDL_mixer}"

# Name of the .env variable holding a library's release tag.
tag_var() {
    case "$1" in
        SDL) echo SDL ;;
        SDL_image) echo SDL_IMAGE ;;
        SDL_ttf) echo SDL_TTF ;;
        SDL_mixer) echo SDL_MIXER ;;
        *) die "unknown library '$1' (expected SDL, SDL_image, SDL_ttf or SDL_mixer)" ;;
    esac
}

# Release tag pinned for a library, e.g. release-3.4.18.
tag_of() {
    local var
    var="$(tag_var "$1")"
    [ -n "${!var:-}" ] || die "$var is not set in .env"
    echo "${!var}"
}

repo_url() { echo "https://github.com/libsdl-org/$1.git"; }

# SDL must come first: the other libraries build against it.
ordered_libs() {
    local lib
    for lib in SDL SDL_image SDL_ttf SDL_mixer; do
        case " $LIBS " in *" $lib "*) echo "$lib" ;; esac
    done
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

# True when PREFIX is a location the toolchain and loader search by default.
is_system_prefix() {
    case "$PREFIX" in
        /usr | /usr/local) return 0 ;;
        *) return 1 ;;
    esac
}
