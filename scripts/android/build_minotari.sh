#!/bin/bash

set -e
cd "$(dirname "$0")"

# Usage: ./build_minotari.sh [esmeralda|mainnet]
# Defaults to mainnet if no argument is provided.

NETWORK_ARG=${1:-mainnet}
echo "Configuring Minotari for network: ${NETWORK_ARG}"
case "${NETWORK_ARG}" in
  esmeralda|esme)
    echo "Selected: Esmeralda (Testnet)"
    export TARI_NETWORK=esme
    export TARI_TARGET_NETWORK=testnet
    ;;
  mainnet)
    echo "Selected: Mainnet (Default)"
    export TARI_NETWORK=mainnet
    export TARI_TARGET_NETWORK=mainnet
    ;;
  *)
    echo "Error: Invalid network specified: '${NETWORK_ARG}'. Supported options are 'mainnet' or 'esmeralda'." >&2
    exit 1
    ;;
esac

CW_MINOTARI_DIR=$(realpath ../..)/cw_minotari
RUST_DIR="${CW_MINOTARI_DIR}/rust"

if [[ ! -d "$RUST_DIR" ]]; then
    echo "Rust directory not found: $RUST_DIR"
    exit 1
fi

if [[ -z "$ANDROID_HOME" ]]; then
    echo "ANDROID_HOME is missing, please declare it before building (on macos it is usually $HOME/Library/Android/sdk)"
    echo "echo > ~/.zprofile"
    echo "echo 'export ANDROID_HOME=\"\$HOME/Library/Android/sdk\"' > ~/.zprofile"
    exit 1
fi

if [[ -z "$ANDROID_NDK_VERSION" ]]; then
    echo "ANDROID_NDK_VERSION is missing, please declare it before building"
    echo "You have these versions installed on your system currently:"
    ls ${ANDROID_HOME}/ndk/ | cat | awk '{ print "- " $1 }'
    echo "echo > ~/.zprofile"
    echo "echo 'export ANDROID_NDK_VERSION=.....' > ~/.zprofile"
    exit 1
fi

export NDK_PATH="${ANDROID_HOME}/ndk/${ANDROID_NDK_VERSION}"
export TOOLCHAIN="${NDK_PATH}/toolchains/llvm/prebuilt/$(uname | tr '[:upper:]' '[:lower:]')-x86_64"
export ANDROID_OUT="${CW_MINOTARI_DIR}/android/src/main/jniLibs"
export OPENSSL_BASE_DIR="$(realpath ../..)/scripts/torch_dart/simplybs/.buildlib/env"

# Ensure Rust Android targets are installed
echo "Installing Rust Android targets..."
rustup target add aarch64-linux-android armv7-linux-androideabi x86_64-linux-android

cd "$RUST_DIR"

# Build for each Android architecture
for arch in "armv7" "aarch64" "x86_64"
do
    RUST_TARGET=""
    ARCH_ABI=""
    AR_PATH=""
    LINKER_PATH=""
    OPENSSL_ARCH_DIR=""

    case $arch in
        "armv7")
            RUST_TARGET="armv7-linux-androideabi"
            ARCH_ABI="armeabi-v7a"
            AR_PATH="${TOOLCHAIN}/bin/llvm-ar"
            LINKER_PATH="${TOOLCHAIN}/bin/armv7a-linux-androideabi21-clang"
            OPENSSL_ARCH_DIR="armv7a-linux-androideabi"
            ;;
        "aarch64")
            RUST_TARGET="aarch64-linux-android"
            ARCH_ABI="arm64-v8a"
            AR_PATH="${TOOLCHAIN}/bin/llvm-ar"
            LINKER_PATH="${TOOLCHAIN}/bin/aarch64-linux-android21-clang"
            OPENSSL_ARCH_DIR="aarch64-linux-android"
            ;;
        "x86_64")
            RUST_TARGET="x86_64-linux-android"
            ARCH_ABI="x86_64"
            AR_PATH="${TOOLCHAIN}/bin/llvm-ar"
            LINKER_PATH="${TOOLCHAIN}/bin/x86_64-linux-android21-clang"
            OPENSSL_ARCH_DIR="x86_64-linux-android"
            ;;
        *)
            echo "Unknown arch: $arch"
            exit 1
            ;;
    esac

    OPENSSL_DIR="${OPENSSL_BASE_DIR}/${OPENSSL_ARCH_DIR}"

    if [[ ! -d "${OPENSSL_DIR}" ]]; then
        echo "OpenSSL directory not found: ${OPENSSL_DIR}"
        echo "Please run ./scripts/android/build_torch.sh first to build OpenSSL"
        exit 1
    fi

    echo "Building for ${RUST_TARGET}..."
    echo "Using OpenSSL from: ${OPENSSL_DIR}"

    # Set environment variables for cross-compilation
    export AR="${AR_PATH}"
    export CC="${LINKER_PATH}"
    export CXX="${LINKER_PATH}++"
    export CARGO_TARGET_ARMV7_LINUX_ANDROIDEABI_LINKER="${TOOLCHAIN}/bin/armv7a-linux-androideabi21-clang"
    export CARGO_TARGET_AARCH64_LINUX_ANDROID_LINKER="${TOOLCHAIN}/bin/aarch64-linux-android21-clang"
    export CARGO_TARGET_X86_64_LINUX_ANDROID_LINKER="${TOOLCHAIN}/bin/x86_64-linux-android21-clang"

    # Set OpenSSL paths to use pre-built libraries
    export OPENSSL_DIR="${OPENSSL_DIR}"
    export OPENSSL_LIB_DIR="${OPENSSL_DIR}/lib"
    export OPENSSL_INCLUDE_DIR="${OPENSSL_DIR}/include"
    export OPENSSL_STATIC=1

    # Build the library
    cargo build --release --target ${RUST_TARGET}

    # Create output directory
    DEST_LIB_DIR="${ANDROID_OUT}/${ARCH_ABI}"
    mkdir -p "${DEST_LIB_DIR}"

    # Copy the library to the jniLibs directory
    cp "target/${RUST_TARGET}/release/librust_lib_flutter_rust_wallet.so" \
       "${DEST_LIB_DIR}/librust_lib_flutter_rust_wallet.so"

    echo "Built ${ARCH_ABI} successfully"
done

echo "All Android architectures built successfully for ${TARI_NETWORK}!"
