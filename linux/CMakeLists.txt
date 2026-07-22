cmake_minimum_required(VERSION 3.10)
project(runner LANGUAGES CXX)

cmake_policy(SET CMP0063 NEW)

set(BINARY_NAME "zero_trust_client")
set(APPLICATION_ID "com.zerotrust.zero_trust_client")

cmake_policy(SET CMP0079 NEW)

set(CMAKE_INSTALL_RPATH "$ORIGIN/lib")

set(CMAKE_BUILD_TYPE "Debug" CACHE
  "Flutter build mode" FORCE)
set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS
  "Debug" "Profile" "Release")

set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/flutter")

add_subdirectory(${FLUTTER_MANAGED_DIR})

add_subdirectory("runner")

include(flutter/generated_plugins.cmake)
