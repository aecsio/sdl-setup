cmake_minimum_required(VERSION 3.20)

# set the output directory for built objects.
# This makes sure that the dynamic library goes into the build directory automatically.
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin") 

# Override output directories for SDL
set(SDL_CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin" CACHE PATH "" FORCE)
set(SDL_CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin" CACHE PATH "" FORCE)
set(SDL_CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin" CACHE PATH "" FORCE)

# Override output directories for SDL_ttf
set(SDLTTF_CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin" CACHE PATH "" FORCE)
set(SDLTTF_CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin" CACHE PATH "" FORCE)
set(SDLTTF_CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin" CACHE PATH "" FORCE)

# Override output directories for SDL_image
set(SDLIMAGE_CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin" CACHE PATH "" FORCE)
set(SDLIMAGE_CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin" CACHE PATH "" FORCE)
set(SDLIMAGE_CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin" CACHE PATH "" FORCE)

# Override output directories for SDL_mixer
set(SDLMIXER_CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin" CACHE PATH "" FORCE)
set(SDLMIXER_CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin" CACHE PATH "" FORCE)
set(SDLMIXER_CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin" CACHE PATH "" FORCE)

# Use vendored libs
set(SDLTTF_VENDORED ON)
set(SDLIMAGE_VENDORED ON)
set(SDLMIXER_VENDORED ON)

# Enable installation for SDL_image
set(SDLIMAGE_INSTALL ON CACHE BOOL "" FORCE)
set(SDLMIXER_INSTALL ON CACHE BOOL "" FORCE)

# Enable installation for SDL and SDL_ttf
set(SDL_INSTALL ON CACHE BOOL "" FORCE)
set(SDLTTF_INSTALL ON CACHE BOOL "" FORCE)
# Ensure static libraries don't skip install if they are built
set(SKIP_INSTALL_LIBRARIES OFF CACHE BOOL "" FORCE)

# Disable AVIF to avoid NASM dependency
set(SDLIMAGE_AVIF OFF CACHE BOOL "" FORCE)

# This assumes the SDL source is available in vendored/SDL
add_subdirectory(SDL)

# This assumes the SDL_ttf source is available in vendored/SDL_ttf
add_subdirectory(SDL_ttf)

# This assumes the SDL_image source is available in vendored/SDL_image
add_subdirectory(SDL_image)

# This assumes the SDL_mixer source is available in vendored/SDL_mixer
add_subdirectory(SDL_mixer)
