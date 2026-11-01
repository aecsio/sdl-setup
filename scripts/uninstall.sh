#!/usr/bin/env bash
# Removes every file sdl-setup ever installed into PREFIX, as recorded by
# install.sh in $PREFIX/share/sdl-setup/<lib>.manifest.
source "$(dirname "$0")/common.sh"

shopt -s nullglob
records=("$MANIFEST_DIR"/*.manifest)
[ "${#records[@]}" -gt 0 ] || die "nothing recorded in $MANIFEST_DIR; nothing to uninstall"

for record in "${records[@]}"; do
    log "$(basename "$record" .manifest): removing $(wc -l < "$record" | tr -d ' ') files"
    tr '\n' '\0' < "$record" | as_installer xargs -0 rm -f --
done
as_installer rm -rf "$MANIFEST_DIR"

refresh_loader_cache
