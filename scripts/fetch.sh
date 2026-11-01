#!/usr/bin/env bash
# Shallow-clones each library at its pinned tag into src/, with the
# third-party submodules (freetype, libpng, ogg, ...) at the exact commits
# that release pins.
source "$(dirname "$0")/common.sh"

mkdir -p "$SRC_DIR"
for lib in $(ordered_libs); do
    tag="$(tag_of "$lib")"
    dir="$SRC_DIR/$lib"
    if [ -d "$dir/.git" ] && [ "$(git -C "$dir" describe --tags --exact-match 2>/dev/null || true)" = "$tag" ]; then
        log "$lib: $tag already fetched"
        continue
    fi
    rm -rf "$dir"
    log "$lib: cloning $tag"
    git -c advice.detachedHead=false clone --quiet --depth 1 --branch "$tag" "$(repo_url "$lib")" "$dir"
    if [ -f "$dir/.gitmodules" ]; then
        log "$lib: fetching pinned submodules"
        git -C "$dir" submodule update --quiet --init --recursive --depth 1 \
            || git -C "$dir" submodule update --quiet --init --recursive
    fi
done
