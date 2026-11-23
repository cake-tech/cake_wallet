#!/bin/bash
set -e

cd "$(dirname "$0")"
source ../simplybs_config.sh

SIMPLYBS_DIR="$HOME/.local/share/simplybs/repo/"
cd $SIMPLYBS_DIR


for i in x86_64-linux-gnu; # soon aarch64 (i hope)
do
    echo "Building for $i"
    go run . -host $i -package $SIMPLYBS_PACKAGES -build
done
