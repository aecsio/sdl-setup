#!/usr/bin/env bash
# Builds each library into build/<lib>. SDL comes first; the other libraries
# build against SDL's build tree, so nothing has to be installed yet.
source "$(dirname "$0")/common.sh"

generator=()
if command -v ninja >/dev/null; then
    generator=(-G Ninja)
fi

common_flags=(
    -DCMAKE_BUILD_TYPE="$BUILD_TYPE"
    -DCMAKE_INSTALL_PREFIX="$PREFIX"
    -DCMAKE_INSTALL_LIBDIR="$LIBDIR"
)
# Always set both, so a cached value from an earlier PREFIX never survives.
if is_system_prefix; then
    # The loader already searches PREFIX; skip the rpath SDL would otherwise
    # put into sdl3.pc (SwiftPM rejects it with a warning).
    common_flags+=(-DCMAKE_INSTALL_RPATH= -DSDL_RPATH=OFF)
else
    # Lets installed libraries, and programs linked through sdl3.pc, find
    # each other in a prefix the loader does not search.
    common_flags+=(-DCMAKE_INSTALL_RPATH="$PREFIX/$LIBDIR" -DSDL_RPATH=ON)
fi

for lib in $(ordered_libs); do
    [ -d "$SRC_DIR/$lib" ] || die "$lib is not fetched; run ./scripts/fetch.sh"
    read -r -a flags <<< "$(lib_cmake_flags "$lib")"
    if [ "$lib" != SDL ]; then
        [ -f "$BUILD_DIR/SDL/SDL3Config.cmake" ] || die "SDL must be built first (add SDL to LIBS)"
        flags+=(-DSDL3_DIR="$BUILD_DIR/SDL")
    fi
    log "$lib: configuring ($BUILD_TYPE, prefix $PREFIX)"
    run_logged "$lib.configure" cmake -S "$SRC_DIR/$lib" -B "$BUILD_DIR/$lib" \
        "${generator[@]}" "${common_flags[@]}" "${flags[@]}"
    log "$lib: building"
    run_logged "$lib.build" cmake --build "$BUILD_DIR/$lib" --parallel
done
