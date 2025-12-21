#!/bin/bash
set -e

# Download external dependencies for SDL_ttf
if [ -d "SDL_ttf/external" ]; then
    echo "Downloading SDL_ttf external dependencies..."
    (cd SDL_ttf/external && ./download.sh)
fi

# Download external dependencies for SDL_image
if [ -d "SDL_image/external" ]; then
    echo "Downloading SDL_image external dependencies..."
    (cd SDL_image/external && ./download.sh)
fi
