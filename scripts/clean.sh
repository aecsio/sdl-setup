#!/usr/bin/env bash
# Removes downloaded sources and build output. Run uninstall.sh first if you
# want to remove installed files: it needs the manifests in build/.
source "$(dirname "$0")/common.sh"

log "removing src/ and build/"
rm -rf "$SRC_DIR" "$BUILD_DIR"
