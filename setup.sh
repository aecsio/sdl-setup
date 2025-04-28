cd SDL
cmake -S . -B build
cmake --build build
sudo cmake --install build

cd ../SDL_ttf
cmake -S . -B build -DSDLTTF_VENDORED=ON
cmake --build build
sudo cmake --install build