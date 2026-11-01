#!/usr/bin/env bash
# Installs the built libraries into PREFIX (sudo only when PREFIX is not
# writable) and records the installed files under $PREFIX/share/sdl-setup,
# so uninstall.sh can remove them later, even after upgrades or clean.sh.
source "$(dirname "$0")/common.sh"

for lib in $(ordered_libs); do
    [ -d "$BUILD_DIR/$lib" ] || die "$lib is not built; run ./scripts/build.sh"
    log "$lib: installing into $PREFIX"
    run_logged "$lib.install" as_installer cmake --install "$BUILD_DIR/$lib"

    # Merge with earlier installs: files from older versions stay recorded.
    record="$MANIFEST_DIR/$lib.manifest"
    as_installer mkdir -p "$MANIFEST_DIR"
    { cat "$BUILD_DIR/$lib/install_manifest.txt"; echo; [ -f "$record" ] && cat "$record"; } \
        | sed '/^$/d' | sort -u | as_installer tee "$record.new" > /dev/null
    as_installer mv "$record.new" "$record"
done

refresh_loader_cache

if ! is_system_prefix; then
    log "$PREFIX is not searched by default; add this to your shell profile:"
    "$ROOT/scripts/env.sh"
fi
