# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

# Project-level configuration.
set(PROJECT_NAME "cw_monero")
project(${PROJECT_NAME} LANGUAGES CXX)

# This value is used when generating builds using this plugin, so it must
# not be changed.
set(PLUGIN_NAME "cw_monero_plugin")

# Define the plugin library target. Its name must not be changed (see comment
# on PLUGIN_NAME above).
#
# Any new source files that you add to the plugin should be added here.
add_library(${PLUGIN_NAME} SHARED
  "cw_monero_plugin.cc"
  "../ios/Classes/monero_api.cpp"
)

# Apply a standard set of build settings that are configured in the
# application-level CMakeLists.txt. This can be removed for plugins that want
# full control over build settings.
apply_standard_settings(${PLUGIN_NAME})

# Symbols are hidden by default to reduce the chance of accidental conflicts
# between plugins. This should not be removed; any symbols that should be
# exported should be explicitly exported with the FLUTTER_PLUGIN_EXPORT macro.
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

# Source include directories and library dependencies. Add any plugin-specific
# dependencies here.
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter)
target_link_libraries(${PLUGIN_NAME} PRIVATE PkgConfig::GTK)
target_link_libraries(${PLUGIN_NAME} PUBLIC cw_monero)
# List of absolute paths to libraries that should be bundled with the plugin.
# This list could contain prebuilt libraries, or libraries created by an
# external build triggered from this build file.
set(cw_monero_bundled_libraries
  ""
  PARENT_SCOPE
)

add_library( cw_monero
             STATIC
             ../ios/Classes/monero_api.cpp)

set(EXTERNAL_LIBS_DIR ${CMAKE_SOURCE_DIR}/../cw_shared_external/ios/External/linux)

############
# libsodium
############

add_library(sodium STATIC IMPORTED)
set_target_properties(sodium PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/lib/libsodium.a)

############
# OpenSSL
############

add_library(crypto STATIC IMPORTED)
set_target_properties(crypto PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/lib/libcrypto.a)

add_library(ssl STATIC IMPORTED)
set_target_properties(ssl PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/lib/libssl.a)

############
# Boost
############

add_library(boost_chrono STATIC IMPORTED)
set_target_properties(boost_chrono PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/lib/libboost_chrono.a)

add_library(boost_date_time STATIC IMPORTED)
set_target_properties(boost_date_time PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/lib/libboost_date_time.a)

add_library(boost_filesystem STATIC IMPORTED)
set_target_properties(boost_filesystem PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/lib/libboost_filesystem.a)

add_library(boost_program_options STATIC IMPORTED)
set_target_properties(boost_program_options PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/lib/libboost_program_options.a)

add_library(boost_regex STATIC IMPORTED)
set_target_properties(boost_regex PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/lib/libboost_regex.a)

add_library(boost_serialization STATIC IMPORTED)
set_target_properties(boost_serialization PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/lib/libboost_serialization.a)

add_library(boost_system STATIC IMPORTED)
set_target_properties(boost_system PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/lib/libboost_system.a)

add_library(boost_thread STATIC IMPORTED)
set_target_properties(boost_thread PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/lib/libboost_thread.a)

add_library(boost_wserialization STATIC IMPORTED)
set_target_properties(boost_wserialization PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/lib/libboost_wserialization.a)

#############
# Monero
#############


add_library(wallet STATIC IMPORTED)
set_target_properties(wallet PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/lib/monero/libwallet.a)
        
add_library(wallet_api STATIC IMPORTED)
set_target_properties(wallet_api PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/lib/monero/libwallet_api.a)

add_library(cryptonote_core STATIC IMPORTED)
set_target_properties(cryptonote_core PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/lib/monero/libcryptonote_core.a)

add_library(cryptonote_basic STATIC IMPORTED)
set_target_properties(cryptonote_basic PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/lib/monero/libcryptonote_basic.a)

add_library(cryptonote_format_utils_basic STATIC IMPORTED)
set_target_properties(cryptonote_format_utils_basic PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/lib/monero/libcryptonote_format_utils_basic.a)        

add_library(mnemonics STATIC IMPORTED)
set_target_properties(mnemonics PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/lib/monero/libmnemonics.a)

add_library(common STATIC IMPORTED)
set_target_properties(common PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/lib/monero/libcommon.a)

add_library(cncrypto STATIC IMPORTED)
set_target_properties(cncrypto PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/lib/monero/libcncrypto.a)

add_library(ringct STATIC IMPORTED)
set_target_properties(ringct PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/lib/monero/libringct.a)

add_library(ringct_basic STATIC IMPORTED)
set_target_properties(ringct_basic PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/lib/monero/libringct_basic.a)

add_library(blockchain_db STATIC IMPORTED)
set_target_properties(blockchain_db PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/lib/monero/libblockchain_db.a)

add_library(lmdb STATIC IMPORTED)
set_target_properties(lmdb PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/lib/monero/liblmdb.a)

add_library(easylogging STATIC IMPORTED)
set_target_properties(easylogging PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/lib/monero/libeasylogging.a)

add_library(epee STATIC IMPORTED)
set_target_properties(epee PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/lib/monero/libepee.a)

add_library(blocks STATIC IMPORTED)
set_target_properties(blocks PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/lib/monero/libblocks.a)

add_library(checkpoints STATIC IMPORTED)
set_target_properties(checkpoints PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/lib/monero/libcheckpoints.a)

add_library(device STATIC IMPORTED)
set_target_properties(device PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/lib/monero/libdevice.a)

add_library(device_trezor STATIC IMPORTED)
set_target_properties(device_trezor PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/lib/monero/libdevice_trezor.a)

add_library(multisig STATIC IMPORTED)
set_target_properties(multisig PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/lib/monero/libmultisig.a)

add_library(version STATIC IMPORTED)
set_target_properties(version PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/lib/monero/libversion.a)

add_library(net STATIC IMPORTED)
set_target_properties(net PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/lib/monero/libnet.a)
        
add_library(hardforks STATIC IMPORTED)
set_target_properties(hardforks PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/lib/monero/libhardforks.a)

add_library(randomx STATIC IMPORTED)
set_target_properties(randomx PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/lib/monero/librandomx.a)

add_library(rpc_base STATIC IMPORTED)
set_target_properties(rpc_base PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/lib/monero/librpc_base.a)

add_library(wallet-crypto STATIC IMPORTED)
set_target_properties(wallet-crypto PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/lib/monero/libwallet-crypto.a)

add_library(unbound STATIC IMPORTED)
set_target_properties(unbound PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/lib/libunbound.a)

include_directories( ${EXTERNAL_LIBS_DIR}/include )

target_link_libraries(  cw_monero
                       
                        wallet_api
                        wallet
                        cryptonote_core
                        cryptonote_basic
                        cryptonote_format_utils_basic
                        mnemonics
                        ringct
                        ringct_basic
                        net
                        common
                        cncrypto
                        blockchain_db
                        lmdb
                        easylogging
                        unbound
                        epee
                        blocks
                        checkpoints
                        device
                        device_trezor
                        multisig
                        version
                        randomx
                        hardforks
                        rpc_base
                        wallet-crypto

                        boost_chrono
                        boost_date_time
                        boost_filesystem
                        boost_program_options
                        boost_regex
                        boost_serialization
                        boost_system
                        boost_thread
                        boost_wserialization

                        ssl
                        crypto
                        
                        sodium
                        )
