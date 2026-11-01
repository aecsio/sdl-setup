#!/usr/bin/env bash
# Lists the system packages SDL needs to build its video and audio backends.
# These are build dependencies of SDL itself, never SDL packages.
# Without the audio headers SDL still builds, but with no real audio output.
#   ./scripts/deps.sh            print the install command
#   ./scripts/deps.sh --install  run it
# Lists follow SDL's docs/README-linux.md.
source "$(dirname "$0")/common.sh"

if is_macos; then
    log "macOS: Xcode command line tools and cmake are enough (xcode-select --install; brew install cmake ninja)"
    exit 0
fi

[ -f /etc/os-release ] || die "cannot detect the Linux distribution"
# shellcheck disable=SC1091
. /etc/os-release
family=" ${ID:-} ${ID_LIKE:-} "

case "$family" in
    *" debian "* | *" ubuntu "*)
        cmd=(apt-get install -y build-essential git pkg-config cmake ninja-build
            libasound2-dev libpulse-dev libpipewire-0.3-dev libjack-dev libsndio-dev libaudio-dev
            libx11-dev libxext-dev libxrandr-dev libxcursor-dev libxfixes-dev libxi-dev libxss-dev libxtst-dev
            libxkbcommon-dev libwayland-dev libdecor-0-dev libdrm-dev libgbm-dev
            libgl1-mesa-dev libgles2-mesa-dev libegl1-mesa-dev
            libdbus-1-dev libibus-1.0-dev libudev-dev libusb-1.0-0-dev liburing-dev libfribidi-dev libthai-dev)
        ;;
    *" fedora "* | *" rhel "*)
        cmd=(dnf install -y gcc gcc-c++ git-core make cmake ninja-build
            alsa-lib-devel pulseaudio-libs-devel pipewire-devel pipewire-jack-audio-connection-kit-devel
            libX11-devel libXext-devel libXrandr-devel libXcursor-devel libXfixes-devel libXi-devel
            libXScrnSaver-devel libXtst-devel libxkbcommon-devel wayland-devel wayland-protocols-devel libdecor-devel
            libdrm-devel mesa-libgbm-devel mesa-libGL-devel mesa-libGLES-devel mesa-libEGL-devel vulkan-devel
            dbus-devel ibus-devel systemd-devel libusb1-devel liburing-devel fribidi-devel libthai-devel)
        ;;
    *" arch "*)
        cmd=(pacman -S --needed base-devel git cmake ninja
            alsa-lib libpulse pipewire jack sndio
            libx11 libxcursor libxext libxfixes libxi libxinerama libxkbcommon libxrandr libxrender libxss libxtst
            wayland wayland-protocols libdecor mesa libgl vulkan-headers
            hidapi ibus libusb fribidi libthai)
        ;;
    *)
        die "unsupported distribution '${ID:-unknown}'; see https://wiki.libsdl.org/SDL3/README-linux"
        ;;
esac

if [ "${1:-}" = "--install" ]; then
    if [ "$(id -u)" = 0 ]; then "${cmd[@]}"; else sudo "${cmd[@]}"; fi
else
    echo "sudo ${cmd[*]}"
fi
