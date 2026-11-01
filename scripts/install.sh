#!/usr/bin/env bash
# Installs the built libraries into PREFIX. Uses sudo only when PREFIX is not
# writable, and refreshes the loader cache for system prefixes on Linux.
source "$(dirname "$0")/common.sh"

for lib in $(ordered_libs); do
    [ -d "$BUILD_DIR/$lib" ] || die "$lib is not built; run ./scripts/build.sh"
    log "$lib: installing into $PREFIX"
    as_installer cmake --install "$BUILD_DIR/$lib" > "$BUILD_DIR/$lib.install.log" 2>&1 \
        || { tail -n 30 "$BUILD_DIR/$lib.install.log"; die "$lib: install failed"; }
done

if ! is_macos && is_system_prefix && command -v ldconfig >/dev/null; then
    log "refreshing the shared library cache"
    as_installer ldconfig
fi

if ! is_system_prefix; then
    log "$PREFIX is not searched by default; add this to your shell profile:"
    "$ROOT/scripts/env.sh"
fi
