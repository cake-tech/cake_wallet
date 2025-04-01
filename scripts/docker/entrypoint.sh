#!/bin/bash
set -x -e

ls /opt/android

rm -rf monero haven

./build_monero.sh
./copy_monero_deps.sh
