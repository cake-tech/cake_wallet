#!/bin/bash
# Build script for PIVX Sapling native library - iOS
# This builds a universal framework for iOS devices and simulators

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUST_DIR="$SCRIPT_DIR/../rust"
OUTPUT_DIR="$SCRIPT_DIR/../ios/Frameworks"
LIB_NAME="cw_pivx_sapling"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Building PIVX Sapling library for iOS...${NC}"

# Check for required tools
if ! command -v cargo &> /dev/null; then
    echo -e "${RED}Error: cargo is not installed. Please install Rust.${NC}"
    exit 1
fi

if ! command -v lipo &> /dev/null; then
    echo -e "${RED}Error: lipo is not installed. Please install Xcode Command Line Tools.${NC}"
    exit 1
fi

# Install iOS targets if not present
rustup target add aarch64-apple-ios
rustup target add aarch64-apple-ios-sim
rustup target add x86_64-apple-ios

cd "$RUST_DIR"

echo -e "${YELLOW}Building for aarch64-apple-ios (device)...${NC}"
cargo build --release --target aarch64-apple-ios

echo -e "${YELLOW}Building for aarch64-apple-ios-sim (Apple Silicon simulator)...${NC}"
cargo build --release --target aarch64-apple-ios-sim

echo -e "${YELLOW}Building for x86_64-apple-ios (Intel simulator)...${NC}"
cargo build --release --target x86_64-apple-ios

# Create output directory
mkdir -p "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR/device"
mkdir -p "$OUTPUT_DIR/simulator"

# Create universal binary for simulators
echo -e "${YELLOW}Creating universal simulator binary...${NC}"
lipo -create \
    target/aarch64-apple-ios-sim/release/lib${LIB_NAME}.a \
    target/x86_64-apple-ios/release/lib${LIB_NAME}.a \
    -output "$OUTPUT_DIR/simulator/lib${LIB_NAME}.a"

# Copy device binary (keep the same name)
cp target/aarch64-apple-ios/release/lib${LIB_NAME}.a "$OUTPUT_DIR/device/lib${LIB_NAME}.a"

# Create xcframework
echo -e "${YELLOW}Creating XCFramework...${NC}"
rm -rf "$OUTPUT_DIR/${LIB_NAME}.xcframework"

xcodebuild -create-xcframework \
    -library "$OUTPUT_DIR/device/lib${LIB_NAME}.a" \
    -library "$OUTPUT_DIR/simulator/lib${LIB_NAME}.a" \
    -output "$OUTPUT_DIR/${LIB_NAME}.xcframework"

# Generate header
echo -e "${YELLOW}Generating C header...${NC}"
cbindgen --lang c --output "$OUTPUT_DIR/cw_pivx_sapling.h" "$RUST_DIR"

# Clean up intermediate files
rm -rf "$OUTPUT_DIR/device"
rm -rf "$OUTPUT_DIR/simulator"

echo -e "${GREEN}✓ iOS build complete!${NC}"
echo -e "${GREEN}  XCFramework: $OUTPUT_DIR/${LIB_NAME}.xcframework${NC}"
echo -e "${GREEN}  Header: $OUTPUT_DIR/cw_pivx_sapling.h${NC}"
