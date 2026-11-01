#!/usr/bin/env bash
# Fetches, builds, installs and verifies the SDL libraries pinned in .env.
set -euo pipefail
cd "$(dirname "$0")"

./scripts/fetch.sh
./scripts/build.sh
./scripts/install.sh
./scripts/verify.sh
