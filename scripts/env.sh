#!/usr/bin/env bash
# Prints the exports that make a non-system PREFIX visible to pkg-config,
# CMake and the dynamic loader. Use: eval "$(./scripts/env.sh)"
source "$(dirname "$0")/common.sh"

if is_macos; then
    loader=DYLD_LIBRARY_PATH
else
    loader=LD_LIBRARY_PATH
fi
echo "export PKG_CONFIG_PATH=\"$PREFIX/lib/pkgconfig\${PKG_CONFIG_PATH:+:\$PKG_CONFIG_PATH}\""
echo "export CMAKE_PREFIX_PATH=\"$PREFIX\${CMAKE_PREFIX_PATH:+:\$CMAKE_PREFIX_PATH}\""
echo "export $loader=\"$PREFIX/lib\${$loader:+:\$$loader}\""
