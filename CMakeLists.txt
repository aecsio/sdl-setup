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


# Use vendored libs
set(SDLTTF_VENDORED ON)

# This assumes the SDL source is available in vendored/SDL
add_subdirectory(SDL EXCLUDE_FROM_ALL)

# This assumes the SDL_ttf source is available in vendored/SDL_ttf
add_subdirectory(SDL_ttf EXCLUDE_FROM_ALL)
