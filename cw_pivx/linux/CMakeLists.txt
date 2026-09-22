cmake_minimum_required(VERSION 3.10)
project(cw_pivx_plugin VERSION 0.0.1 LANGUAGES CXX)

# Specify the C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Set plugin name
set(PLUGIN_NAME "cw_pivx_plugin")

# Define the plugin library
add_library(${PLUGIN_NAME} SHARED
  cw_pivx_plugin.cc
)

# Apply standard settings for a Flutter plugin
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden
)

# Link against Flutter embedder
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include"
)
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter)

# Link the PIVX Sapling native library
target_link_libraries(${PLUGIN_NAME} PRIVATE
  ${CMAKE_CURRENT_SOURCE_DIR}/lib/libcw_pivx_sapling.a
  pthread
  dl
  m
)

# Bundle the native library
install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/lib/libcw_pivx_sapling.a"
  DESTINATION "${CMAKE_INSTALL_PREFIX}/lib"
)

# List of public headers
target_include_directories(${PLUGIN_NAME} PUBLIC
  "${CMAKE_CURRENT_SOURCE_DIR}/include"
)
