cmake_minimum_required(VERSION 3.14)
project(zero_trust_client LANGUAGES CXX)

set(BINARY_NAME "zero_trust_client")

cmake_policy(VERSION 3.14...3.25)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/flutter")

add_subdirectory(${FLUTTER_MANAGED_DIR})

add_subdirectory("runner")

include(flutter/generated_plugins.cmake)
