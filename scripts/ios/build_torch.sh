#!/bin/bash
set -x -e
cd "$(dirname "$0")"

../prepare_torch.sh

cd ../torch_dart

# Need to build all platforms to get .xcframework
./build.sh aarch64-apple-ios-simulator aarch64-apple-ios aarch64-apple-darwin x86_64-apple-darwin