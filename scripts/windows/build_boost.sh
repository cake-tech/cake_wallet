#!/bin/bash
. ./config.sh

./build_iconv.sh

BOOST_FILENAME=boost_1_78_0.tar.bz2
BOOST_FILE_PATH=$CACHEDIR/$BOOST_FILENAME
BOOST_SRC_DIR=$WORKDIR/boost_1_78_0
BOOST_VERSION=1.78.0
BOOST_SHA256="8681f175d4bdb26c52222665793eef08490d7758529330f98d3b29dd0735bccc"

if [ ! -e "$BOOST_FILE_PATH" ]; then
	wget -O $BOOST_FILE_PATH https://boostorg.jfrog.io/artifactory/main/release/1.78.0/source/$BOOST_FILENAME
fi

echo $BOOST_SHA256 $BOOST_FILE_PATH | sha256sum -c - || exit 1

cd $WORKDIR
rm -rf $BOOST_SRC_DIR
tar -xjf $BOOST_FILE_PATH -C $WORKDIR
cp ../user-config.jam $BOOST_SRC_DIR/user-config.jam
cd $BOOST_SRC_DIR

./bootstrap.sh \
  --prefix="${PREFIX}" \
  --with-toolset=gcc

# See https://gist.github.com/Shauren/5c28f646bf7a28b470a8 for boost link flags (add -lws2_32?)

CC=x86_64-w64-mingw32.static-gcc
CXX=x86_64-w64-mingw32.static-g++
HOST=x86_64-w64-mingw32.static
./b2 release -d2 \
	cxxflags=-fPIC \
	cflags=-fPIC \
	variant=release \
	--layout=tagged \
	--build-type=minimal \
	--user-config=user-config.jam \
	threading=multi \
	link=static \
	-sNO_BZIP2=1 \
	-sNO_ZLIB=1 \
	binary-format=pe \
	target-os=windows \
	threadapi=win32 \
	runtime-link=static \
	address-model=64 \
	--with-chrono \
	--with-filesystem \
	--with-program_options \
	--with-system \
	--with-thread \
	--with-test \
	--with-date_time \
	--with-regex \
	--with-serialization \
	--with-locale \
	--verbose \
	--build-dir=windows \
	--stagedir=windows \
	threadapi=pthread \
	toolset=gcc-mingw \
	-sICONV_PATH=${PREFIX} \
	define=BOOST_USE_WINDOWS_H \
	-j$THREADS install

cd ${PREFIX}/lib
mv libboost_system-mt-s-x64.a				libboost_system.a
mv libboost_atomic-mt-s-x64.a				libboost_atomic.a
mv libboost_filesystem-mt-s-x64.a			libboost_filesystem.a
mv libboost_program_options-mt-s-x64.a		libboost_program_options.a
mv libboost_unit_test_framework-mt-s-x64.a	libboost_unit_test_framework.a
mv libboost_chrono-mt-s-x64.a				libboost_chrono.a
mv libboost_locale-mt-s-x64.a				libboost_locale.a
mv libboost_regex-mt-s-x64.a				libboost_regex.a
mv libboost_test_exec_monitor-mt-s-x64.a	libboost_test_exec_monitor.a
mv libboost_wserialization-mt-s-x64.a		libboost_wserialization.a
mv libboost_date_time-mt-s-x64.a			libboost_date_time.a
mv libboost_prg_exec_monitor-mt-s-x64.a		libboost_prg_exec_monitor.a
mv libboost_serialization-mt-s-x64.a		libboost_serialization.a
mv libboost_thread-mt-s-x64.a				libboost_thread.a
echo 'Renaming files if needed, mv issues above are warnings, not errors'

: 'Having to rename libraries may be a sign that we should build boost differently in order to match the expected names:
-- [ /usr/share/cmake-3.16/Modules/FindBoost.cmake:2058 ] Searching for SYSTEM_LIBRARY_RELEASE: boost_system-gcc9-mt-1_78;boost_system-gcc9-mt;boost_system-gcc9-mt;boost_system-mt-1_78;boost_system-mt;boost_system-mt;boost_system-mt;boost_system
-- [ /usr/share/cmake-3.16/Modules/FindBoost.cmake:2113 ] Searching for SYSTEM_LIBRARY_DEBUG: boost_system-gcc9-mt-d-1_78;boost_system-gcc9-mt-d;boost_system-gcc9-mt-d;boost_system-mt-d-1_78;boost_system-mt-d;boost_system-mt-d;boost_system-mt;boost_system
-- [ /usr/share/cmake-3.16/Modules/FindBoost.cmake:2058 ] Searching for FILESYSTEM_LIBRARY_RELEASE: boost_filesystem-gcc9-mt-1_78;boost_filesystem-gcc9-mt;boost_filesystem-gcc9-mt;boost_filesystem-mt-1_78;boost_filesystem-mt;boost_filesystem-mt;boost_filesystem-mt;boost_filesystem
-- [ /usr/share/cmake-3.16/Modules/FindBoost.cmake:2113 ] Searching for FILESYSTEM_LIBRARY_DEBUG: boost_filesystem-gcc9-mt-d-1_78;boost_filesystem-gcc9-mt-d;boost_filesystem-gcc9-mt-d;boost_filesystem-mt-d-1_78;boost_filesystem-mt-d;boost_filesystem-mt-d;boost_filesystem-mt;boost_filesystem
-- [ /usr/share/cmake-3.16/Modules/FindBoost.cmake:2058 ] Searching for THREAD_LIBRARY_RELEASE: boost_thread-gcc9-mt-1_78;boost_thread-gcc9-mt;boost_thread-gcc9-mt;boost_thread-mt-1_78;boost_thread-mt;boost_thread-mt;boost_thread-mt;boost_thread
-- [ /usr/share/cmake-3.16/Modules/FindBoost.cmake:2113 ] Searching for THREAD_LIBRARY_DEBUG: boost_thread-gcc9-mt-d-1_78;boost_thread-gcc9-mt-d;boost_thread-gcc9-mt-d;boost_thread-mt-d-1_78;boost_thread-mt-d;boost_thread-mt-d;boost_thread-mt;boost_thread
-- [ /usr/share/cmake-3.16/Modules/FindBoost.cmake:2058 ] Searching for DATE_TIME_LIBRARY_RELEASE: boost_date_time-gcc9-mt-1_78;boost_date_time-gcc9-mt;boost_date_time-gcc9-mt;boost_date_time-mt-1_78;boost_date_time-mt;boost_date_time-mt;boost_date_time-mt;boost_date_time
-- [ /usr/share/cmake-3.16/Modules/FindBoost.cmake:2113 ] Searching for DATE_TIME_LIBRARY_DEBUG: boost_date_time-gcc9-mt-d-1_78;boost_date_time-gcc9-mt-d;boost_date_time-gcc9-mt-d;boost_date_time-mt-d-1_78;boost_date_time-mt-d;boost_date_time-mt-d;boost_date_time-mt;boost_date_time
-- [ /usr/share/cmake-3.16/Modules/FindBoost.cmake:2058 ] Searching for CHRONO_LIBRARY_RELEASE: boost_chrono-gcc9-mt-1_78;boost_chrono-gcc9-mt;boost_chrono-gcc9-mt;boost_chrono-mt-1_78;boost_chrono-mt;boost_chrono-mt;boost_chrono-mt;boost_chrono
-- [ /usr/share/cmake-3.16/Modules/FindBoost.cmake:2113 ] Searching for CHRONO_LIBRARY_DEBUG: boost_chrono-gcc9-mt-d-1_78;boost_chrono-gcc9-mt-d;boost_chrono-gcc9-mt-d;boost_chrono-mt-d-1_78;boost_chrono-mt-d;boost_chrono-mt-d;boost_chrono-mt;boost_chrono
-- [ /usr/share/cmake-3.16/Modules/FindBoost.cmake:2058 ] Searching for REGEX_LIBRARY_RELEASE: boost_regex-gcc9-mt-1_78;boost_regex-gcc9-mt;boost_regex-gcc9-mt;boost_regex-mt-1_78;boost_regex-mt;boost_regex-mt;boost_regex-mt;boost_regex
-- [ /usr/share/cmake-3.16/Modules/FindBoost.cmake:2113 ] Searching for REGEX_LIBRARY_DEBUG: boost_regex-gcc9-mt-d-1_78;boost_regex-gcc9-mt-d;boost_regex-gcc9-mt-d;boost_regex-mt-d-1_78;boost_regex-mt-d;boost_regex-mt-d;boost_regex-mt;boost_regex
-- [ /usr/share/cmake-3.16/Modules/FindBoost.cmake:2058 ] Searching for SERIALIZATION_LIBRARY_RELEASE: boost_serialization-gcc9-mt-1_78;boost_serialization-gcc9-mt;boost_serialization-gcc9-mt;boost_serialization-mt-1_78;boost_serialization-mt;boost_serialization-mt;boost_serialization-mt;boost_serialization
-- [ /usr/share/cmake-3.16/Modules/FindBoost.cmake:2113 ] Searching for SERIALIZATION_LIBRARY_DEBUG: boost_serialization-gcc9-mt-d-1_78;boost_serialization-gcc9-mt-d;boost_serialization-gcc9-mt-d;boost_serialization-mt-d-1_78;boost_serialization-mt-d;boost_serialization-mt-d;boost_serialization-mt;boost_serialization
-- [ /usr/share/cmake-3.16/Modules/FindBoost.cmake:2058 ] Searching for PROGRAM_OPTIONS_LIBRARY_RELEASE: boost_program_options-gcc9-mt-1_78;boost_program_options-gcc9-mt;boost_program_options-gcc9-mt;boost_program_options-mt-1_78;boost_program_options-mt;boost_program_options-mt;boost_program_options-mt;boost_program_options
-- [ /usr/share/cmake-3.16/Modules/FindBoost.cmake:2113 ] Searching for PROGRAM_OPTIONS_LIBRARY_DEBUG: boost_program_options-gcc9-mt-d-1_78;boost_program_options-gcc9-mt-d;boost_program_options-gcc9-mt-d;boost_program_options-mt-d-1_78;boost_program_options-mt-d;boost_program_options-mt-d;boost_program_options-mt;boost_program_options
-- [ /usr/share/cmake-3.16/Modules/FindBoost.cmake:2058 ] Searching for LOCALE_LIBRARY_RELEASE: boost_locale-gcc9-mt-1_78;boost_locale-gcc9-mt;boost_locale-gcc9-mt;boost_locale-mt-1_78;boost_locale-mt;boost_locale-mt;boost_locale-mt;boost_locale
-- [ /usr/share/cmake-3.16/Modules/FindBoost.cmake:2113 ] Searching for LOCALE_LIBRARY_DEBUG: boost_locale-gcc9-mt-d-1_78;boost_locale-gcc9-mt-d;boost_locale-gcc9-mt-d;boost_locale-mt-d-1_78;boost_locale-mt-d;boost_locale-mt-d;boost_locale-mt;boost_locale
-- [ /usr/share/cmake-3.16/Modules/FindBoost.cmake:2058 ] Searching for ATOMIC_LIBRARY_RELEASE: boost_atomic-gcc9-mt-1_78;boost_atomic-gcc9-mt;boost_atomic-gcc9-mt;boost_atomic-mt-1_78;boost_atomic-mt;boost_atomic-mt;boost_atomic-mt;boost_atomic
-- [ /usr/share/cmake-3.16/Modules/FindBoost.cmake:2113 ] Searching for ATOMIC_LIBRARY_DEBUG: boost_atomic-gcc9-mt-d-1_78;boost_atomic-gcc9-mt-d;boost_atomic-gcc9-mt-d;boost_atomic-mt-d-1_78;boost_atomic-mt-d;boost_atomic-mt-d;boost_atomic-mt;boost_atomic
'
