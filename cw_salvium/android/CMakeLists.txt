cmake_minimum_required(VERSION 3.4.1)

add_library( cw_salvium
             SHARED
             ../ios/Classes/salvium_api.cpp)

             find_library( log-lib log )

set(EXTERNAL_LIBS_DIR ${CMAKE_SOURCE_DIR}/../../cw_shared_external/ios/External/android)

############
# libsodium
############

add_library(sodium STATIC IMPORTED)
set_target_properties(sodium PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/${ANDROID_ABI}/lib/libsodium.a)

############
# OpenSSL
############

add_library(crypto STATIC IMPORTED)
set_target_properties(crypto PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/${ANDROID_ABI}/lib/libcrypto.a)

add_library(ssl STATIC IMPORTED)
set_target_properties(ssl PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/${ANDROID_ABI}/lib/libssl.a)

############
# Boost
############

add_library(boost_chrono STATIC IMPORTED)
set_target_properties(boost_chrono PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/${ANDROID_ABI}/lib/libboost_chrono.a)

add_library(boost_date_time STATIC IMPORTED)
set_target_properties(boost_date_time PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/${ANDROID_ABI}/lib/libboost_date_time.a)

add_library(boost_filesystem STATIC IMPORTED)
set_target_properties(boost_filesystem PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/${ANDROID_ABI}/lib/libboost_filesystem.a)

add_library(boost_program_options STATIC IMPORTED)
set_target_properties(boost_program_options PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/${ANDROID_ABI}/lib/libboost_program_options.a)

add_library(boost_regex STATIC IMPORTED)
set_target_properties(boost_regex PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/${ANDROID_ABI}/lib/libboost_regex.a)

add_library(boost_serialization STATIC IMPORTED)
set_target_properties(boost_serialization PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/${ANDROID_ABI}/lib/libboost_serialization.a)

add_library(boost_system STATIC IMPORTED)
set_target_properties(boost_system PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/${ANDROID_ABI}/lib/libboost_system.a)

add_library(boost_thread STATIC IMPORTED)
set_target_properties(boost_thread PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/${ANDROID_ABI}/lib/libboost_thread.a)

add_library(boost_wserialization STATIC IMPORTED)
set_target_properties(boost_wserialization PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/${ANDROID_ABI}/lib/libboost_wserialization.a)

#############
# Salvium
#############

add_library(wallet_api STATIC IMPORTED)
set_target_properties(wallet_api PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/${ANDROID_ABI}/lib/salvium/libwallet_api.a)

add_library(wallet STATIC IMPORTED)
set_target_properties(wallet PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/${ANDROID_ABI}/lib/salvium/libwallet.a)

add_library(cryptonote_core STATIC IMPORTED)
set_target_properties(cryptonote_core PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/${ANDROID_ABI}/lib/salvium/libcryptonote_core.a)

add_library(cryptonote_basic STATIC IMPORTED)
set_target_properties(cryptonote_basic PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/${ANDROID_ABI}/lib/salvium/libcryptonote_basic.a)

add_library(mnemonics STATIC IMPORTED)
set_target_properties(mnemonics PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/${ANDROID_ABI}/lib/salvium/libmnemonics.a)

add_library(common STATIC IMPORTED)
set_target_properties(common PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/${ANDROID_ABI}/lib/salvium/libcommon.a)

add_library(cncrypto STATIC IMPORTED)
set_target_properties(cncrypto PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/${ANDROID_ABI}/lib/salvium/libcncrypto.a)

add_library(ringct STATIC IMPORTED)
set_target_properties(ringct PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/${ANDROID_ABI}/lib/salvium/libringct.a)

add_library(ringct_basic STATIC IMPORTED)
set_target_properties(ringct_basic PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/${ANDROID_ABI}/lib/salvium/libringct_basic.a)

add_library(blockchain_db STATIC IMPORTED)
set_target_properties(blockchain_db PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/${ANDROID_ABI}/lib/salvium/libblockchain_db.a)

add_library(lmdb STATIC IMPORTED)
set_target_properties(lmdb PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/${ANDROID_ABI}/lib/salvium/liblmdb.a)

add_library(easylogging STATIC IMPORTED)
set_target_properties(easylogging PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/${ANDROID_ABI}/lib/salvium/libeasylogging.a)

add_library(unbound STATIC IMPORTED)
set_target_properties(unbound PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/${ANDROID_ABI}/lib/salvium/libunbound.a)

add_library(epee STATIC IMPORTED)
set_target_properties(epee PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/${ANDROID_ABI}/lib/salvium/libepee.a)

add_library(checkpoints STATIC IMPORTED)
set_target_properties(checkpoints PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/${ANDROID_ABI}/lib/salvium/libcheckpoints.a)

add_library(device STATIC IMPORTED)
set_target_properties(device PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/${ANDROID_ABI}/lib/salvium/libdevice.a)

add_library(device_trezor STATIC IMPORTED)
set_target_properties(device_trezor PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/${ANDROID_ABI}/lib/salvium/libdevice_trezor.a)

add_library(multisig STATIC IMPORTED)
set_target_properties(multisig PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/${ANDROID_ABI}/lib/salvium/libmultisig.a)

add_library(version STATIC IMPORTED)
set_target_properties(version PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/${ANDROID_ABI}/lib/salvium/libversion.a)

add_library(net STATIC IMPORTED)
set_target_properties(net PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/${ANDROID_ABI}/lib/salvium/libnet.a)
        
add_library(hardforks STATIC IMPORTED)
set_target_properties(hardforks PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/${ANDROID_ABI}/lib/salvium/libhardforks.a)

add_library(randomx STATIC IMPORTED)
set_target_properties(randomx PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/${ANDROID_ABI}/lib/salvium/librandomx.a)
        
add_library(offshore STATIC IMPORTED)
set_target_properties(offshore PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/${ANDROID_ABI}/lib/salvium/liboffshore.a)


add_library(rpc_base STATIC IMPORTED)
set_target_properties(rpc_base PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/${ANDROID_ABI}/lib/salvium/librpc_base.a)

add_library(wallet-crypto STATIC IMPORTED)
set_target_properties(wallet-crypto PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/${ANDROID_ABI}/lib/salvium/libwallet-crypto.a)

include_directories( ${EXTERNAL_LIBS_DIR}/${ANDROID_ABI}/include )

target_link_libraries(  cw_salvium
                       
                        wallet_api
                        wallet
                        cryptonote_core
                        cryptonote_basic
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
                        checkpoints
                        device
                        device_trezor
                        multisig
                        version
                        randomx
                        offshore
                        hardforks
                        rpc_base

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

                        ${log-lib} )