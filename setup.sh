#!/bin/bash
set -e

# Configure and build everything together
cmake -S . -B build
cmake --build build

echo ""
echo "Installing globally..."
sudo cmake --install build
sudo ldconfig
