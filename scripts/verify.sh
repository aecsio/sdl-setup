#!/usr/bin/env bash
# Checks the installed libraries the way a consumer sees them:
#   1. pkg-config finds every library
#   2. the versions loaded at runtime match the tags pinned in .env
#   3. SDL was built with a real video and audio backend (not only dummy ones)
#   4. the dynamic loader resolves everything (the test program runs)
source "$(dirname "$0")/common.sh"

if ! is_system_prefix; then
    eval "$("$ROOT/scripts/env.sh")"
fi

command -v pkg-config >/dev/null || die "pkg-config is required"

pc_name() {
    case "$1" in
        SDL) echo sdl3 ;;
        SDL_image) echo sdl3-image ;;
        SDL_ttf) echo sdl3-ttf ;;
        SDL_mixer) echo sdl3-mixer ;;
    esac
}

fail=0
pcs=()
for lib in $(ordered_libs); do
    pc="$(pc_name "$lib")"
    want="$(tag_of "$lib")"; want="${want#release-}"
    if have="$(pkg-config --modversion "$pc" 2>/dev/null)"; then
        if [ "$have" = "$want" ]; then
            log "pkg-config $pc: $have"
        else
            warn "pkg-config $pc: found $have, expected $want"
            fail=1
        fi
        pcs+=("$pc")
    else
        warn "pkg-config cannot find $pc"
        fail=1
    fi
done
[ "$fail" = 0 ] || die "pkg-config checks failed"

dir="$BUILD_DIR/verify"
mkdir -p "$dir"
{
    echo '#include <stdio.h>'
    echo '#include <SDL3/SDL.h>'
    for lib in $(ordered_libs); do
        case "$lib" in
            SDL_image) echo '#include <SDL3_image/SDL_image.h>' ;;
            SDL_ttf) echo '#include <SDL3_ttf/SDL_ttf.h>' ;;
            SDL_mixer) echo '#include <SDL3_mixer/SDL_mixer.h>' ;;
        esac
    done
    cat <<'C'
static void version(const char *name, int v) {
    printf("version %s %d.%d.%d\n", name, SDL_VERSIONNUM_MAJOR(v), SDL_VERSIONNUM_MINOR(v), SDL_VERSIONNUM_MICRO(v));
}
int main(void) {
    version("SDL", SDL_GetVersion());
C
    for lib in $(ordered_libs); do
        case "$lib" in
            SDL_image) echo '    version("SDL_image", IMG_Version());' ;;
            SDL_ttf) echo '    version("SDL_ttf", TTF_Version());' ;;
            SDL_mixer) echo '    version("SDL_mixer", MIX_Version());' ;;
        esac
    done
    cat <<'C'
    for (int i = 0; i < SDL_GetNumVideoDrivers(); i++) printf("video %s\n", SDL_GetVideoDriver(i));
    for (int i = 0; i < SDL_GetNumAudioDrivers(); i++) printf("audio %s\n", SDL_GetAudioDriver(i));
    return 0;
}
C
} > "$dir/verify.c"

log "compiling a test program against ${pcs[*]}"
# shellcheck disable=SC2046
cc "$dir/verify.c" -o "$dir/verify" $(pkg-config --cflags --libs "${pcs[@]}") \
    || die "the test program does not compile or link"

log "running it"
out="$("$dir/verify")" || die "the test program does not run (dynamic loader cannot resolve the libraries?)"

for lib in $(ordered_libs); do
    want="$(tag_of "$lib")"; want="${want#release-}"
    have="$(printf '%s\n' "$out" | awk -v n="$lib" '$1 == "version" && $2 == n { print $3 }')"
    if [ "$have" = "$want" ]; then
        log "runtime $lib: $have"
    else
        warn "runtime $lib: loaded ${have:-nothing}, expected $want (an older copy shadowing it?)"
        fail=1
    fi
done

video="$(printf '%s\n' "$out" | awk '$1 == "video" { print $2 }')"
audio="$(printf '%s\n' "$out" | awk '$1 == "audio" { print $2 }')"
log "video drivers: $(printf '%s\n' "$video" | paste -sd' ')"
log "audio drivers: $(printf '%s\n' "$audio" | paste -sd' ')"

if is_macos; then
    real_video='cocoa'; real_audio='coreaudio'
else
    real_video='x11|wayland|kmsdrm'; real_audio='pipewire|pulseaudio|alsa|jack|sndio'
fi
if ! printf '%s\n' "$video" | grep -qxE "$real_video"; then
    warn "no real video driver was built; install the headers from ./scripts/deps.sh and rebuild"
    fail=1
fi
if ! printf '%s\n' "$audio" | grep -qxE "$real_audio"; then
    warn "no real audio driver was built; install the headers from ./scripts/deps.sh and rebuild"
    fail=1
fi

[ "$fail" = 0 ] || die "verification failed"
log "all checks passed"
