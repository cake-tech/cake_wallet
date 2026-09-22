#!/bin/bash
# Build script for PIVX Sapling native library - Linux
# This builds for the current Linux architecture

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUST_DIR="$SCRIPT_DIR/../rust"
OUTPUT_DIR="$SCRIPT_DIR/../linux/lib"
LIB_NAME="cw_pivx_sapling"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Building PIVX Sapling library for Linux...${NC}"

# Check for required tools
if ! command -v cargo &> /dev/null; then
    echo -e "${RED}Error: cargo is not installed. Please install Rust.${NC}"
    exit 1
fi

cd "$RUST_DIR"

echo -e "${YELLOW}Building for current architecture...${NC}"
cargo build --release

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Determine target directory
TARGET_DIR="target/release"

# Copy library
if [ -f "$TARGET_DIR/lib${LIB_NAME}.so" ]; then
    cp "$TARGET_DIR/lib${LIB_NAME}.so" "$OUTPUT_DIR/"
    echo -e "${GREEN}✓ Built lib${LIB_NAME}.so${NC}"
fi

if [ -f "$TARGET_DIR/lib${LIB_NAME}.a" ]; then
    cp "$TARGET_DIR/lib${LIB_NAME}.a" "$OUTPUT_DIR/"
    echo -e "${GREEN}✓ Built lib${LIB_NAME}.a${NC}"
fi

# Generate header
echo -e "${YELLOW}Generating C header...${NC}"
if command -v cbindgen &> /dev/null; then
    cbindgen --lang c --output "$OUTPUT_DIR/cw_pivx_sapling.h" "$RUST_DIR"
else
    echo -e "${YELLOW}cbindgen not found, skipping header generation${NC}"
fi

echo -e "${GREEN}✓ Linux build complete!${NC}"
echo -e "${GREEN}  Output: $OUTPUT_DIR${NC}"
