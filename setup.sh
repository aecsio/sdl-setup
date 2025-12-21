#!/bin/bash
set -e

# Configure and build everything together
cmake -S . -B build
cmake --build build

echo ""
echo "Build complete. Libraries are in build/bin"
echo "To install globally, run:"
echo "sudo cmake --install build"
