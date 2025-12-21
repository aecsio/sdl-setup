Deps

```sh
sudo apt install build-essential cmake
```

[build by os](https://github.com/libsdl-org/SDL/blob/main/docs/README-cmake.md)
[deps per linux distro](https://wiki.libsdl.org/SDL3/README/linux)

download latest [SDL 3.x release](https://github.com/libsdl-org/SDL/releases)


UPDATE submodules:

```sh
git submodule update --init --recursive --remote
```
```sh
git submodule update --init --recursive --depth 1
```

Build everything (SDL3, SDL_ttf, SDL_image) and download dependencies:
```sh
./setup.sh
```

This will build the libraries in `build/bin`.

To install globally (optional):
```sh
sudo cmake --install build
```

---

Created submodules using:
```sh
git submodule add --depth 1 git@github.com:libsdl-org/SDL.git 
git submodule add --depth 1 git@github.com:libsdl-org/SDL_ttf.git
git submodule add --depth 1 git@github.com:libsdl-org/SDL_image.git
```
