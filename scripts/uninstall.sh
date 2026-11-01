#!/usr/bin/env bash
# Removes exactly the files the last install wrote, as recorded by CMake in
# build/<lib>/install_manifest.txt.
source "$(dirname "$0")/common.sh"

found=0
for lib in SDL_mixer SDL_ttf SDL_image SDL; do
    manifest="$BUILD_DIR/$lib/install_manifest.txt"
    [ -f "$manifest" ] || continue
    found=1
    log "$lib: removing $(wc -l < "$manifest" | tr -d ' ') files"
    while IFS= read -r file; do
        if [ -e "$file" ] || [ -L "$file" ]; then
            as_installer rm -f "$file"
        fi
    done < "$manifest"
done
[ "$found" = 1 ] || die "no install manifests in build/; nothing to uninstall"

if ! is_macos && is_system_prefix && command -v ldconfig >/dev/null; then
    as_installer ldconfig
fi
