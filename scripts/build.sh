#!/usr/bin/env bash
# Builds each library into build/<lib>. SDL comes first; the other libraries
# build against SDL's build tree, so nothing has to be installed yet.
source "$(dirname "$0")/common.sh"

mkdir -p "$BUILD_DIR"

generator=()
if command -v ninja >/dev/null; then
    generator=(-G Ninja)
fi

common_flags=(
    -DCMAKE_BUILD_TYPE="$BUILD_TYPE"
    -DCMAKE_INSTALL_PREFIX="$PREFIX"
)
if is_system_prefix; then
    # The loader already searches system prefixes; skip the rpath SDL would
    # otherwise put into sdl3.pc (SwiftPM rejects it with a warning).
    common_flags+=(-DSDL_RPATH=OFF)
else
    # Lets installed libraries, and programs linked through sdl3.pc, find
    # each other in a prefix the loader does not search.
    common_flags+=(-DCMAKE_INSTALL_RPATH="$PREFIX/lib" -DSDL_RPATH=ON)
fi

lib_flags() {
    case "$1" in
        SDL)
            echo -DSDL_TESTS=OFF -DSDL_EXAMPLES=OFF
            ;;
        SDL_image)
            # Bundled codecs, linked in. AVIF needs nasm and is off.
            echo -DSDLIMAGE_VENDORED=ON -DSDLIMAGE_DEPS_SHARED=OFF -DSDLIMAGE_AVIF=OFF \
                -DSDLIMAGE_SAMPLES=OFF -DSDLIMAGE_TESTS=OFF
            ;;
        SDL_ttf)
            # Bundled freetype, harfbuzz and plutosvg.
            echo -DSDLTTF_VENDORED=ON -DSDLTTF_SAMPLES=OFF
            ;;
        SDL_mixer)
            # Bundled codecs (ogg/vorbis, opus, flac, mp3, ...), linked in.
            echo -DSDLMIXER_VENDORED=ON -DSDLMIXER_DEPS_SHARED=OFF \
                -DSDLMIXER_TESTS=OFF -DSDLMIXER_EXAMPLES=OFF
            ;;
    esac
}

for lib in $(ordered_libs); do
    [ -d "$SRC_DIR/$lib" ] || die "$lib is not fetched; run ./scripts/fetch.sh"
    flags=()
    read -r -a flags <<< "$(lib_flags "$lib")"
    if [ "$lib" != SDL ]; then
        [ -f "$BUILD_DIR/SDL/SDL3Config.cmake" ] || die "SDL must be built first (add SDL to LIBS)"
        flags+=(-DSDL3_DIR="$BUILD_DIR/SDL")
    fi
    log "$lib: configuring ($BUILD_TYPE, prefix $PREFIX)"
    cmake -S "$SRC_DIR/$lib" -B "$BUILD_DIR/$lib" "${generator[@]}" "${common_flags[@]}" "${flags[@]}" > "$BUILD_DIR/$lib.configure.log" 2>&1 \
        || { tail -n 30 "$BUILD_DIR/$lib.configure.log"; die "$lib: configure failed (full log: build/$lib.configure.log)"; }
    log "$lib: building"
    cmake --build "$BUILD_DIR/$lib" --parallel > "$BUILD_DIR/$lib.build.log" 2>&1 \
        || { tail -n 30 "$BUILD_DIR/$lib.build.log"; die "$lib: build failed (full log: build/$lib.build.log)"; }
done
