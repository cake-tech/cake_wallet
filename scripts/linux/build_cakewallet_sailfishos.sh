#!/bin/bash
set -x
set -e
cd "$(dirname "$0")"
cd ../..

docker run -w $PWD -v $PWD:$PWD --rm -it ghcr.io/mrcyjanek/sailfishos:4.6.0.11_target_aarch64 bash -c "cd elinux && ./sailfish-prepare.sh && ./sailfish-build.sh"
