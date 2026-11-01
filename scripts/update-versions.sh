#!/usr/bin/env bash
# Rewrites the release tags in .env with the latest stable release of each library.
# Stable SDL releases are tagged release-X.Y.Z with an even minor version Y.
# Review the diff and commit it.
source "$(dirname "$0")/common.sh"

latest_stable_tag() {
    git ls-remote --tags --refs "$(repo_url "$1")" 'release-3.*' \
        | sed 's#.*refs/tags/##' \
        | grep -E '^release-3\.[0-9]*[02468]\.[0-9]+$' \
        | sort -V \
        | tail -n 1
}

changed=0
for lib in "${ALL_LIBS[@]}"; do
    var="$(lib_var "$lib")"
    current="$(grep -E "^$var=" "$ROOT/.env" | cut -d= -f2- || true)"
    latest="$(latest_stable_tag "$lib")"
    [ -n "$latest" ] || die "could not find a stable release tag for $lib"
    if [ "$current" = "$latest" ]; then
        log "$lib: $current (up to date)"
    else
        log "$lib: ${current:-unset} -> $latest"
        tmp="$(mktemp)"
        awk -v k="$var" -v v="$latest" '
            $0 ~ "^" k "=" { print k "=" v; done = 1; next }
            { print }
            END { if (!done) print k "=" v }
        ' "$ROOT/.env" > "$tmp"
        mv "$tmp" "$ROOT/.env"
        changed=1
    fi
done

if [ "$changed" = 1 ]; then
    log "updated .env; review with 'git diff .env', then run ./setup.sh"
fi
