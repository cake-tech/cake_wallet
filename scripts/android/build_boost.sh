# /bin/bash

WORKDIR=/opt/android
TOOLCHAIN_BASE_DIR=${WORKDIR}/toolchain
ORIGINAL_PATH=$PATH

for arch in "aarch" "aarch64" "i686" "x86_64"
do

PREFIX=$WORKDIR/prefix_${arch}
PATH="${TOOLCHAIN_BASE_DIR}_${arch}/bin:${ORIGINAL_PATH}"

./init_boost.sh $arch
./finish_boost.sh $arch

done
