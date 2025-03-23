#!/bin/bash

# build_cake_release.sh - Script to build Cake Wallet for Linux
# Usage: ./build_cake_release.sh --amd64 [--arm64] [--app=cakewallet|monero.com]

set -e


SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"


# Default values
BUILD_AMD64=false
BUILD_ARM64=false
APP_TYPE="cakewallet"
DOCKER_IMAGE="ghcr.io/cake-tech/cake_wallet:debian12-flutter3.27.4-go1.24.1"

# Parse arguments
for arg in "$@"
do
    case $arg in
        --amd64)
        BUILD_AMD64=true
        shift
        ;;
        --arm64)
        BUILD_ARM64=true
        shift
        ;;
        --app=*)
        APP_TYPE="${arg#*=}"
        shift
        ;;
        *)
        echo "Unknown argument: $arg"
        echo "Usage: ./build_cake_release.sh --amd64 [--arm64] [--app=cakewallet|monero.com]"
        exit 1
        ;;
    esac
done

cd ../..

# Validate arguments
if [[ "$BUILD_AMD64" == "false" && "$BUILD_ARM64" == "false" ]]; then
    echo "Error: At least one architecture (--amd64 or --arm64) must be specified."
    echo "Usage: ./build_cake_release.sh --amd64 [--arm64] [--app=cakewallet|monero.com]"
    exit 1
fi

if [[ "$APP_TYPE" != "cakewallet" && "$APP_TYPE" != "monero.com" ]]; then
    echo "Error: App type must be either 'cakewallet' or 'monero.com'"
    echo "Usage: ./build_cake_release.sh --amd64 [--arm64] [--app=cakewallet|monero.com]"
    exit 1
fi

# Function to build for a specific architecture
build_for_arch() {
    local arch=$1
    echo "Building $APP_TYPE for Linux ($arch)"
    
    docker run --privileged -v$(pwd):$(pwd) -w $(pwd) -i --rm --platform linux/$arch $DOCKER_IMAGE bash -x << EOF
set -x -e
pushd scripts
    ./gen_android_manifest.sh
popd
pushd scripts/linux
    source ./app_env.sh $APP_TYPE
    ./app_config.sh
    ./build_monero_all.sh
popd
flutter clean
./model_generator.sh
dart run tool/generate_localization.dart
flutter build linux
cp -r build/linux/* build/linux/current
flatpak-builder --force-clean flatpak-build com.cakewallet.CakeWallet.yml
flatpak build-export export flatpak-build
flatpak build-bundle export build/linux/current/cake_wallet.flatpak com.cakewallet.CakeWallet
EOF
    
    # Move the build to a platform-specific directory
    mkdir -p build/linux/$arch
    cp -r build/linux/current/release/bundle build/linux/$arch/
    echo "$arch build completed. Output is in build/linux/$arch/bundle/"
}

# Build for specified architectures
echo "Building $APP_TYPE for Linux"
if [[ "$BUILD_AMD64" == "true" ]]; then
    build_for_arch "amd64"
fi

if [[ "$BUILD_ARM64" == "true" ]]; then
    build_for_arch "arm64"
fi

echo "Build process completed."
