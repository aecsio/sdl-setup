Deps

```sh
sudo apt install build-essential cmake
```

[build by os](https://github.com/libsdl-org/SDL/blob/main/docs/README-cmake.md)
[deps per linux distro](https://wiki.libsdl.org/SDL3/README/linux)

download latest [SDL 3.x release](https://github.com/libsdl-org/SDL/releases)


UPDATE
```sh
git submodule update --init --recursive --depth 1
```

build:
```sh
cmake -S . -B build
cmake --build build
```

update the dynamic linker cache after build

```sh
sudo ldconfig
```

---

created submodules using:
```sh
git submodule add --depth 1 git@github.com:libsdl-org/SDL.git 
git submodule add --depth 1 git@github.com:libsdl-org/SDL_ttf.git
git submodule add --depth 1 git@github.com:libsdl-org/SDL_image.git
```

Resolve external TTF deps
```sh
./SDL_ttf/external/download.sh
```
