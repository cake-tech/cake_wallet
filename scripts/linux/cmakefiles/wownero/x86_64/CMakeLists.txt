cmake_minimum_required(VERSION 3.4.1)

add_library( cw_wownero
             SHARED
#             ../../../cw_wownero/android/jni/wownero_jni.cpp
             ../../../../../cw_wownero/ios/Classes/wownero_api.cpp)

set(EXTERNAL_LIBS_DIR ${CMAKE_SOURCE_DIR}/../../../build)

############
# libsodium
############

add_library(sodium STATIC IMPORTED)
set_target_properties(sodium PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/prefix_x86_64/lib/libsodium.a)

############
# OpenSSL
############

add_library(crypto STATIC IMPORTED)
set_target_properties(crypto PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/prefix_x86_64/lib/libcrypto.a)

add_library(ssl STATIC IMPORTED)
set_target_properties(ssl PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/prefix_x86_64/lib/libssl.a)

############
# wownero-seed
############

add_library(wownero-seed STATIC IMPORTED)
set_target_properties(wownero-seed PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/prefix_x86_64/lib/libwownero-seed.a)

############
# Boost
############

add_library(boost_chrono STATIC IMPORTED)
set_target_properties(boost_chrono PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/prefix_x86_64/lib/libboost_chrono.a)

add_library(boost_date_time STATIC IMPORTED)
set_target_properties(boost_date_time PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/prefix_x86_64/lib/libboost_date_time.a)

add_library(boost_filesystem STATIC IMPORTED)
set_target_properties(boost_filesystem PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/prefix_x86_64/lib/libboost_filesystem.a)

add_library(boost_program_options STATIC IMPORTED)
set_target_properties(boost_program_options PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/prefix_x86_64/lib/libboost_program_options.a)

add_library(boost_regex STATIC IMPORTED)
set_target_properties(boost_regex PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/prefix_x86_64/lib/libboost_regex.a)

add_library(boost_serialization STATIC IMPORTED)
set_target_properties(boost_serialization PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/prefix_x86_64/lib/libboost_serialization.a)

add_library(boost_system STATIC IMPORTED)
set_target_properties(boost_system PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/prefix_x86_64/lib/libboost_system.a)

add_library(boost_thread STATIC IMPORTED)
set_target_properties(boost_thread PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/prefix_x86_64/lib/libboost_thread.a)

add_library(boost_wserialization STATIC IMPORTED)
set_target_properties(boost_wserialization PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/prefix_x86_64/lib/libboost_wserialization.a)

#############
# Wownero
#############

add_library(wallet_api STATIC IMPORTED)
set_target_properties(wallet_api PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/prefix_x86_64/lib/wownero/libwallet_api.a)

add_library(wallet STATIC IMPORTED)
set_target_properties(wallet PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/prefix_x86_64/lib/wownero/libwallet.a)

add_library(cryptonote_core STATIC IMPORTED)
set_target_properties(cryptonote_core PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/prefix_x86_64/lib/wownero/libcryptonote_core.a)

add_library(cryptonote_basic STATIC IMPORTED)
set_target_properties(cryptonote_basic PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/prefix_x86_64/lib/wownero/libcryptonote_basic.a)

add_library(cryptonote_format_utils_basic STATIC IMPORTED)
set_target_properties(cryptonote_format_utils_basic PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/prefix_x86_64/lib/wownero/libcryptonote_format_utils_basic.a)

add_library(mnemonics STATIC IMPORTED)
set_target_properties(mnemonics PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/prefix_x86_64/lib/wownero/libmnemonics.a)

add_library(common STATIC IMPORTED)
set_target_properties(common PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/prefix_x86_64/lib/wownero/libcommon.a)

add_library(cncrypto STATIC IMPORTED)
set_target_properties(cncrypto PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/prefix_x86_64/lib/wownero/libcncrypto.a)

add_library(ringct STATIC IMPORTED)
set_target_properties(ringct PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/prefix_x86_64/lib/wownero/libringct.a)

add_library(ringct_basic STATIC IMPORTED)
set_target_properties(ringct_basic PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/prefix_x86_64/lib/wownero/libringct_basic.a)

add_library(blockchain_db STATIC IMPORTED)
set_target_properties(blockchain_db PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/prefix_x86_64/lib/wownero/libblockchain_db.a)

add_library(lmdb STATIC IMPORTED)
set_target_properties(lmdb PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/prefix_x86_64/lib/wownero/liblmdb.a)

add_library(easylogging STATIC IMPORTED)
set_target_properties(easylogging PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/prefix_x86_64/lib/wownero/libeasylogging.a)

add_library(unbound STATIC IMPORTED)
set_target_properties(unbound PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/prefix_x86_64/lib/wownero/libunbound.a)

add_library(epee STATIC IMPORTED)
set_target_properties(epee PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/prefix_x86_64/lib/wownero/libepee.a)

add_library(blocks STATIC IMPORTED)
set_target_properties(blocks PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/prefix_x86_64/lib/wownero/libblocks.a)

add_library(checkpoints STATIC IMPORTED)
set_target_properties(checkpoints PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/prefix_x86_64/lib/wownero/libcheckpoints.a)

add_library(device STATIC IMPORTED)
set_target_properties(device PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/prefix_x86_64/lib/wownero/libdevice.a)

add_library(device_trezor STATIC IMPORTED)
set_target_properties(device_trezor PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/prefix_x86_64/lib/wownero/libdevice_trezor.a)

add_library(multisig STATIC IMPORTED)
set_target_properties(multisig PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/prefix_x86_64/lib/wownero/libmultisig.a)

add_library(version STATIC IMPORTED)
set_target_properties(version PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/prefix_x86_64/lib/wownero/libversion.a)

add_library(net STATIC IMPORTED)
set_target_properties(net PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/prefix_x86_64/lib/wownero/libnet.a)
        
add_library(hardforks STATIC IMPORTED)
set_target_properties(hardforks PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/prefix_x86_64/lib/wownero/libhardforks.a)

add_library(randomx STATIC IMPORTED)
set_target_properties(randomx PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/prefix_x86_64/lib/wownero/librandomx.a)

add_library(rpc_base STATIC IMPORTED)
set_target_properties(rpc_base PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/prefix_x86_64/lib/wownero/librpc_base.a)

add_library(wallet-crypto STATIC IMPORTED)
set_target_properties(wallet-crypto PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/prefix_x86_64/lib/wownero/libwallet-crypto.a)

set(WALLET_CRYPTO "wallet-crypto")

include_directories( ${EXTERNAL_LIBS_DIR}/prefix_x86_64/include )

target_link_libraries(  cw_wownero
                       
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
                        ${WALLET_CRYPTO}

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

                        -Wl,--whole-archive
                        wownero-seed
                        -Wl,--no-whole-archive )