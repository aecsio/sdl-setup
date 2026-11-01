#!/usr/bin/env bash
# Shallow-clones each library at its pinned tag into src/, with the
# third-party submodules (freetype, libpng, ogg, ...) at the exact commits
# that release pins. Submodules the build does not use are skipped.
source "$(dirname "$0")/common.sh"

mkdir -p "$SRC_DIR"
for lib in $(ordered_libs); do
    tag="$(tag_of "$lib")"
    dir="$SRC_DIR/$lib"
    if [ -d "$dir/.git" ] && [ "$(git -C "$dir" describe --tags --exact-match 2>/dev/null || true)" = "$tag" ]; then
        log "$lib: $tag already cloned"
    else
        rm -rf "$dir"
        log "$lib: cloning $tag"
        git -c advice.detachedHead=false clone --quiet --depth 1 --branch "$tag" "$(repo_url "$lib")" "$dir"
    fi

    # Always run: cheap when complete, and it resumes an interrupted fetch.
    [ -f "$dir/.gitmodules" ] || continue
    read -r -a unused <<< "$(lib_unused_submodules "$lib")"
    paths=()
    while read -r _ path; do
        case " ${unused[*]} " in *" $path "*) ;; *) paths+=("$path") ;; esac
    done < <(git -C "$dir" config -f .gitmodules --get-regexp '\.path$')
    log "$lib: fetching ${#paths[@]} pinned submodules"
    git -C "$dir" submodule update --quiet --init --recursive --depth 1 --jobs 8 -- "${paths[@]}" \
        || git -C "$dir" submodule update --quiet --init --recursive --jobs 8 -- "${paths[@]}"
done
