cmake_minimum_required(VERSION 3.4.1)

add_library( cw_zano
             SHARED
             ../ios/Classes/zano_api.cpp)

             find_library( log-lib log )

set(EXTERNAL_LIBS_DIR ${CMAKE_SOURCE_DIR}/../../cw_shared_external/ios/External/android)
set(EXTERNAL_ZANO_ROOT ${CMAKE_SOURCE_DIR}/../../../zano)



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

add_library(boost_log STATIC IMPORTED)
        set_target_properties(boost_log PROPERTIES IMPORTED_LOCATION
                ${EXTERNAL_LIBS_DIR}/${ANDROID_ABI}/lib/libboost_log.a)
        
#############
# Zano
#############
add_library(zano_common STATIC IMPORTED)
set_target_properties(zano_common PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/${ANDROID_ABI}/lib/zano/libcommon.a)


add_library(zano_crypto STATIC IMPORTED)
set_target_properties(zano_crypto PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/${ANDROID_ABI}/lib/zano/libcrypto.a)

add_library(zano_currency_core STATIC IMPORTED)
set_target_properties(zano_currency_core PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/${ANDROID_ABI}/lib/zano/libcurrency_core.a)

add_library(zano_z STATIC IMPORTED)
set_target_properties(zano_z PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/${ANDROID_ABI}/lib/zano/libz.a)

add_library(zano_wallet STATIC IMPORTED)
set_target_properties(zano_wallet PROPERTIES IMPORTED_LOCATION
        ${EXTERNAL_LIBS_DIR}/${ANDROID_ABI}/lib/zano/libwallet.a)

include_directories( ${EXTERNAL_LIBS_DIR}/${ANDROID_ABI}/include )
include_directories( ${EXTERNAL_ZANO_ROOT}/src/wallet )


target_link_libraries(  cw_zano
                        zano_common
                        zano_crypto
                        zano_currency_core
                        zano_z
                        zano_wallet

                        boost_chrono
                        boost_date_time
                        boost_filesystem
                        boost_program_options
                        boost_regex
                        boost_serialization
                        boost_system
                        boost_thread
                        boost_wserialization
                        boost_log

                        ssl
                        crypto
                        ${log-lib}
                        )