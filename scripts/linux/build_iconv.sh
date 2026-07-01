#!/bin/sh

set -e

. ./config.sh

export ICONV_FILENAME=libiconv-1.16.tar.gz
export ICONV_FILE_PATH=${EXTERNAL_LINUX_SOURCE_DIR}/${ICONV_FILENAME}
export ICONV_SRC_DIR=${EXTERNAL_LINUX_SOURCE_DIR}/libiconv-1.16
ICONV_SHA256="e6a1b1b589654277ee790cce3734f07876ac4ccfaecbee8afa0b649cf529cc04"

curl http://ftp.gnu.org/pub/gnu/libiconv/${ICONV_FILENAME} -o $ICONV_FILE_PATH
echo $ICONV_SHA256 $ICONV_FILE_PATH | sha256sum -c - || exit 1

cd $EXTERNAL_LINUX_SOURCE_DIR
rm -rf $ICONV_SRC_DIR
tar -xzf $ICONV_FILE_PATH -C $EXTERNAL_LINUX_SOURCE_DIR
cd $ICONV_SRC_DIR

./configure --prefix=${EXTERNAL_LINUX_DIR}
make
make install
