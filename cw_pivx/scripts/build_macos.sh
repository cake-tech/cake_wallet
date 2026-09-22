#!/bin/bash
# Build script for PIVX Sapling native library - macOS
# This builds a universal dylib for macOS (arm64 + x86_64)

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUST_DIR="$SCRIPT_DIR/../rust"
OUTPUT_DIR="$SCRIPT_DIR/../macos/Frameworks"
LIB_NAME="cw_pivx_sapling"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Building PIVX Sapling library for macOS...${NC}"

# Check for required tools
if ! command -v cargo &> /dev/null; then
    echo -e "${RED}Error: cargo is not installed. Please install Rust.${NC}"
    exit 1
fi

# Install macOS targets
rustup target add aarch64-apple-darwin
rustup target add x86_64-apple-darwin

cd "$RUST_DIR"

echo -e "${YELLOW}Building for aarch64-apple-darwin (Apple Silicon)...${NC}"
cargo build --release --target aarch64-apple-darwin

echo -e "${YELLOW}Building for x86_64-apple-darwin (Intel)...${NC}"
cargo build --release --target x86_64-apple-darwin

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Create universal binary
echo -e "${YELLOW}Creating universal binary...${NC}"
lipo -create \
    target/aarch64-apple-darwin/release/lib${LIB_NAME}.dylib \
    target/x86_64-apple-darwin/release/lib${LIB_NAME}.dylib \
    -output "$OUTPUT_DIR/lib${LIB_NAME}.dylib"

# Also create static library
lipo -create \
    target/aarch64-apple-darwin/release/lib${LIB_NAME}.a \
    target/x86_64-apple-darwin/release/lib${LIB_NAME}.a \
    -output "$OUTPUT_DIR/lib${LIB_NAME}.a"

# Generate header
echo -e "${YELLOW}Generating C header...${NC}"
cbindgen --lang c --output "$OUTPUT_DIR/cw_pivx_sapling.h" "$RUST_DIR"

echo -e "${GREEN}✓ macOS build complete!${NC}"
echo -e "${GREEN}  Dynamic library: $OUTPUT_DIR/lib${LIB_NAME}.dylib${NC}"
echo -e "${GREEN}  Static library: $OUTPUT_DIR/lib${LIB_NAME}.a${NC}"
echo -e "${GREEN}  Header: $OUTPUT_DIR/cw_pivx_sapling.h${NC}"
