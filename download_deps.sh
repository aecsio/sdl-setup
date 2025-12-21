#!/bin/bash
set -e

# Function to download dependencies for a module by parsing its .gitmodules file
# This is a robust replacement for the internal download.sh scripts, ensuring idempotency.
download_module_deps() {
    local module_dir="$1"
    
    if [ ! -d "$module_dir" ]; then
        echo "Module directory $module_dir not found. Skipping."
        return
    fi
    
    echo "Processing dependencies for $module_dir..."
    
    (
        cd "$module_dir" || exit 1
        
        if [ ! -f .gitmodules ]; then
            echo "  No .gitmodules found."
            exit 0
        fi

        # Parse .gitmodules
        # We assume the standard format used by SDL satellite libraries:
        # [submodule "name"]
        #     path = ...
        #     url = ...
        #     branch = ...
        cat .gitmodules | while true; do
            read module_header || break
            
            read path_line || break
            set -- $path_line
            path="$3"
            
            read url_line || break
            set -- $url_line
            url="$3"
            
            read branch_line || break
            set -- $branch_line
            branch="$3"
            
            if [ -z "$path" ] || [ -z "$url" ] || [ -z "$branch" ]; then
                # If we encounter empty vars (e.g. at end of file), break or continue
                continue
            fi
            
            if [ -d "$path" ] && [ "$(ls -A "$path")" ]; then
                echo "  Dependency '$path' already exists and is not empty. Skipping."
            else
                echo "  Cloning $path..."
                # Use strict cloning usage mirroring the original scripts
                git clone --filter=blob:none "$url" "$path" -b "$branch" --recursive --depth 1
            fi
        done
    )
}

# Download external dependencies for submodules
download_module_deps "SDL_ttf"
download_module_deps "SDL_image"
download_module_deps "SDL_mixer"
