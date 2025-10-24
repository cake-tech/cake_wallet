#!/bin/bash

cd "$(dirname $0)"

set -x -e

../prepare_reown.sh

../reown_flutter/scripts/build_native_deps.sh
cd ../reown_flutter/scripts/yttrium/
./generate_kotlin_locally.sh