#!/bin/bash
set -x -e
cd "$(dirname "$0")"

../prepare_torch.sh

cd ../torch_dart

./build.sh aarch64-linux-android armv7a-linux-androideabi x86_64-linux-android