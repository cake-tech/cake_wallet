#!/bin/sh

. ./config.sh

SEED_DIR=$WORKDIR/seed
SEED_TAG=0.3.0
SEED_COMMIT_HASH="ef6910b6bb3b61757c36e2e5db0927d75f1731c8"

for arch in "aarch" "aarch64" "i686" "x86_64"
do

FLAGS=""
PREFIX=$WORKDIR/prefix_${arch}
DEST_LIB_DIR=${PREFIX}/lib/
DEST_INCLUDE_DIR=${PREFIX}/include/
export CMAKE_INCLUDE_PATH="${PREFIX}/include"
export CMAKE_LIBRARY_PATH="${PREFIX}/lib"
ANDROID_STANDALONE_TOOLCHAIN_PATH="${TOOLCHAIN_BASE_DIR}_${arch}"
PATH="${ANDROID_STANDALONE_TOOLCHAIN_PATH}/bin:${ORIGINAL_PATH}"

case $arch in
	"aarch"	)
		CLANG=arm-linux-androideabi-clang
 		CXXLANG=arm-linux-androideabi-clang++
		BUILD_64=OFF
		TAG="android-armv7"
		ARCH="armv7-a"
		ARCH_ABI="armeabi-v7a"
		FLAGS="-D CMAKE_ANDROID_ARM_MODE=ON";;
	"aarch64"	)
		CLANG=aarch64-linux-androideabi-clang
 		CXXLANG=aarch64-linux-androideabi-clang++
		BUILD_64=ON
		TAG="android-armv8"
		ARCH="armv8-a"
		ARCH_ABI="arm64-v8a";;
	"i686"		)
		CLANG=i686-linux-androideabi-clang
 		CXXLANG=i686-linux-androideabi-clang++
		BUILD_64=OFF
		TAG="android-x86"
		ARCH="i686"
		ARCH_ABI="x86";;
	"x86_64"	)
		CLANG=x86_64-linux-androideabi-clang
 		CXXLANG=x86_64-linux-androideabi-clang++
		BUILD_64=ON
		TAG="android-x86_64"
		ARCH="x86-64"
		ARCH_ABI="x86_64";;
esac

cd $WORKDIR

rm -rf $SEED_DIR
git clone -b $SEED_TAG --depth 1 https://git.wownero.com/wowlet/wownero-seed.git $SEED_DIR
cd $SEED_DIR
git reset --hard $SEED_COMMIT_HASH

CC={$CLANG} CXX={$CXXLANG} cmake -Bbuild -DCMAKE_ANDROID_NDK="${ANDROID_NDK_HOME}" -DANDROID_PLATFORM="android-${API}" -DCMAKE_SYSTEM_VERSION="${API}"  -DCMAKE_INSTALL_PREFIX=${PREFIX} ARCH=${ARCH} -D CMAKE_BUILD_TYPE=Release -D CMAKE_SYSTEM_NAME="Android" -D CMAKE_ANDROID_STANDALONE_TOOLCHAIN="${ANDROID_STANDALONE_TOOLCHAIN_PATH}" -D CMAKE_ANDROID_ARCH_ABI=${ARCH_ABI} $FLAGS .

make -Cbuild -j$THREADS
make -Cbuild install

done

