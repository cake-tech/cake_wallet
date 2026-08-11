#!/bin/bash
set -x -e
cd "$(dirname "$0")"

../prepare_torch.sh

cd ../torch_dart

# ./build.sh x86_64-linux-gnu
