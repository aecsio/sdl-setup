#!/usr/bin/env bash
# Checks the installed libraries the way a consumer sees them:
#   1. pkg-config finds every library
#   2. the versions loaded at runtime match the tags pinned in .env
#   3. SDL was built with a real video and audio backend (not only dummy ones)
#   4. the dynamic loader resolves everything (the test program runs)
source "$(dirname "$0")/common.sh"

command -v pkg-config >/dev/null || die "pkg-config is required"

# Only point pkg-config at a non-system PREFIX: the test program must find the
# libraries at runtime on its own (loader path or rpath), like a real consumer.
if ! is_system_prefix; then
    export PKG_CONFIG_PATH="$PREFIX/$LIBDIR/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
fi

mapfile -t libs < <(ordered_libs)

fail=0
pcs=()
for lib in "${libs[@]}"; do
    pc="$(lib_pc "$lib")"
    want="$(version_of "$lib")"
    if ! have="$(pkg-config --modversion "$pc" 2>/dev/null)"; then
        warn "pkg-config cannot find $pc"
        fail=1
    elif [ "$have" != "$want" ]; then
        warn "pkg-config $pc: found $have, expected $want"
        fail=1
    else
        log "pkg-config $pc: $have"
    fi
    pcs+=("$pc")
done
[ "$fail" = 0 ] || die "pkg-config checks failed"

dir="$BUILD_DIR/verify"
mkdir -p "$dir"
{
    echo '#include <stdio.h>'
    for lib in "${libs[@]}"; do echo "#include <$(lib_header "$lib")>"; done
    echo 'static void version(const char *name, int v) {'
    printf '%s\n' '    printf("version %s %d.%d.%d\n", name, SDL_VERSIONNUM_MAJOR(v), SDL_VERSIONNUM_MINOR(v), SDL_VERSIONNUM_MICRO(v));'
    echo '}'
    echo 'int main(void) {'
    for lib in "${libs[@]}"; do echo "    version(\"$lib\", $(lib_version_fn "$lib")());"; done
    printf '%s\n' '    for (int i = 0; i < SDL_GetNumVideoDrivers(); i++) printf("video %s\n", SDL_GetVideoDriver(i));'
    printf '%s\n' '    for (int i = 0; i < SDL_GetNumAudioDrivers(); i++) printf("audio %s\n", SDL_GetAudioDriver(i));'
    echo '    return 0;'
    echo '}'
} > "$dir/verify.c"

log "compiling a test program against ${pcs[*]}"
read -r -a pc_flags <<< "$(pkg-config --cflags --libs "${pcs[@]}")"
cc "$dir/verify.c" -o "$dir/verify" "${pc_flags[@]}" || die "the test program does not compile or link"

log "running it"
out="$("$dir/verify")" || die "the test program does not run (dynamic loader cannot resolve the libraries?)"

for lib in "${libs[@]}"; do
    want="$(version_of "$lib")"
    have="$(awk -v n="$lib" '$1 == "version" && $2 == n { print $3 }' <<< "$out")"
    if [ "$have" = "$want" ]; then
        log "runtime $lib: $have"
    else
        warn "runtime $lib: loaded ${have:-nothing}, expected $want (an older copy shadowing it?)"
        fail=1
    fi
done

video="$(awk '$1 == "video" { print $2 }' <<< "$out")"
audio="$(awk '$1 == "audio" { print $2 }' <<< "$out")"
log "video drivers: $(paste -sd' ' <<< "$video")"
log "audio drivers: $(paste -sd' ' <<< "$audio")"

if is_macos; then
    real_video='cocoa'; real_audio='coreaudio'
else
    real_video='x11|wayland|kmsdrm'; real_audio='pipewire|pulseaudio|alsa|jack|sndio'
fi
if ! grep -qxE "$real_video" <<< "$video"; then
    warn "no real video driver was built; install the headers from ./scripts/deps.sh and rebuild"
    fail=1
fi
if ! grep -qxE "$real_audio" <<< "$audio"; then
    warn "no real audio driver was built; install the headers from ./scripts/deps.sh and rebuild"
    fail=1
fi

[ "$fail" = 0 ] || die "verification failed"
log "all checks passed"
