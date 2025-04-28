Deps

```sh
sudo apt install build-essential cmake
```

[build by os](https://github.com/libsdl-org/SDL/blob/main/docs/README-cmake.md)
[deps per linux distro](https://wiki.libsdl.org/SDL3/README/linux)

download latest [SDL 3.x release](https://github.com/libsdl-org/SDL/releases)

auto setup.sh


update the dynamic linker cache after build

```sh
sudo ldconfig
```

./SDL_ttf/external/download.sh

git submodule update --init --recursive --depth 1

git submodule add --depth 1 git@github.com:libsdl-org/SDL.git 
git submodule add --depth 1 git@github.com:libsdl-org/SDL_ttf.git

cmake -S . -B build
cmake --build build