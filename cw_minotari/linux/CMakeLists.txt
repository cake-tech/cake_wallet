cmake_minimum_required(VERSION 3.10)

# Unpacked by scripts/prepare_minotari.sh linux
set(cw_minotari_bundled_libraries
  "${CMAKE_CURRENT_SOURCE_DIR}/lib/libminotari_wallet_ffi.so"
  PARENT_SCOPE
)
