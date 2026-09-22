#!/bin/bash
# Build script for PIVX Sapling native library - Android
# This builds for all Android architectures (arm64-v8a, armeabi-v7a, x86_64, x86)

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUST_DIR="$SCRIPT_DIR/../rust"
OUTPUT_DIR="$SCRIPT_DIR/../android/src/main/jniLibs"
LIB_NAME="cw_pivx_sapling"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Building PIVX Sapling library for Android...${NC}"

# Check for required tools
if ! command -v cargo &> /dev/null; then
    echo -e "${RED}Error: cargo is not installed. Please install Rust.${NC}"
    exit 1
fi

# Check for Android NDK
if [ -z "$ANDROID_NDK_HOME" ]; then
    # Try common locations
    if [ -d "$HOME/Library/Android/sdk/ndk" ]; then
        ANDROID_NDK_HOME=$(ls -d "$HOME/Library/Android/sdk/ndk"/*/ | tail -1)
    elif [ -d "$ANDROID_HOME/ndk" ]; then
        ANDROID_NDK_HOME=$(ls -d "$ANDROID_HOME/ndk"/*/ | tail -1)
    elif [ -d "/usr/local/lib/android/sdk/ndk" ]; then
        ANDROID_NDK_HOME=$(ls -d "/usr/local/lib/android/sdk/ndk"/*/ | tail -1)
    fi
fi

if [ -z "$ANDROID_NDK_HOME" ]; then
    echo -e "${RED}Error: ANDROID_NDK_HOME is not set. Please set it to your NDK path.${NC}"
    exit 1
fi

echo -e "${YELLOW}Using NDK: $ANDROID_NDK_HOME${NC}"

# Install Android targets
rustup target add aarch64-linux-android
rustup target add armv7-linux-androideabi
rustup target add x86_64-linux-android
rustup target add i686-linux-android

# Install cargo-ndk if not present
if ! command -v cargo-ndk &> /dev/null; then
    echo -e "${YELLOW}Installing cargo-ndk...${NC}"
    cargo install cargo-ndk
fi

cd "$RUST_DIR"

# Create output directories
mkdir -p "$OUTPUT_DIR/arm64-v8a"
mkdir -p "$OUTPUT_DIR/armeabi-v7a"
mkdir -p "$OUTPUT_DIR/x86_64"
mkdir -p "$OUTPUT_DIR/x86"

# Build for each architecture
echo -e "${YELLOW}Building for arm64-v8a...${NC}"
cargo ndk -t arm64-v8a -o "$OUTPUT_DIR" build --release

echo -e "${YELLOW}Building for armeabi-v7a...${NC}"
cargo ndk -t armeabi-v7a -o "$OUTPUT_DIR" build --release

echo -e "${YELLOW}Building for x86_64...${NC}"
cargo ndk -t x86_64 -o "$OUTPUT_DIR" build --release

echo -e "${YELLOW}Building for x86...${NC}"
cargo ndk -t x86 -o "$OUTPUT_DIR" build --release

# Rename libraries to match expected names
missing_arch=false
for arch in arm64-v8a armeabi-v7a x86_64 x86; do
    if [ -s "$OUTPUT_DIR/$arch/lib${LIB_NAME}.so" ]; then
        echo -e "${GREEN}✓ Built lib${LIB_NAME}.so for $arch${NC}"
    else
        echo -e "${RED}✗ Failed to build for $arch${NC}"
        missing_arch=true
    fi
done

if [ "$missing_arch" = true ]; then
    echo -e "${RED}Error: one or more Android PIVX Sapling libraries are missing.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Android build complete!${NC}"
echo -e "${GREEN}  Libraries: $OUTPUT_DIR${NC}"
