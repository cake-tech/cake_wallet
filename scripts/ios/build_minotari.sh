#!/bin/bash
#
# Build Minotari Rust library for iOS
# Creates an xcframework supporting both device and simulator
#

set -e
cd "$(dirname "$0")"

CW_ROOT=$(realpath ../..);
CW_MINOTARI_DIR="${CW_ROOT}/cw_minotari"
RUST_DIR="${CW_MINOTARI_DIR}/rust"
IOS_OUT="${CW_MINOTARI_DIR}/ios"
FRAMEWORKS_DIR="${IOS_OUT}/Frameworks"
XCFRAMEWORK_NAME="RustMinotari"

if [[ ! -d "$RUST_DIR" ]]; then
    echo "Error: Rust directory not found: $RUST_DIR"
    echo "Please run scripts/prepare_minotari.sh first"
    exit 1
fi

# Ensure Rust iOS targets are installed
echo "Installing Rust iOS targets..."
rustup target add aarch64-apple-ios aarch64-apple-ios-sim x86_64-apple-ios

# Create output directories
mkdir -p "${FRAMEWORKS_DIR}"
cd "$RUST_DIR"

# Clean previous builds
rm -rf "${FRAMEWORKS_DIR}/${XCFRAMEWORK_NAME}.xcframework"

# Build for iOS device (arm64)
echo "Building for iOS device (aarch64-apple-ios)..."
cargo build --release --target aarch64-apple-ios

# Build for iOS simulator (arm64 - Apple Silicon)
echo "Building for iOS simulator arm64 (aarch64-apple-ios-sim)..."
cargo build --release --target aarch64-apple-ios-sim

# Build for iOS simulator (x86_64 - Intel Macs)
echo "Building for iOS simulator x86_64 (x86_64-apple-ios)..."
cargo build --release --target x86_64-apple-ios

# Create fat library for simulator (combining arm64 and x86_64)
echo "Creating fat library for simulator..."
SIMULATOR_FAT_DIR="${RUST_DIR}/target/ios-simulator-fat"
mkdir -p "${SIMULATOR_FAT_DIR}"

lipo -create \
    "${RUST_DIR}/target/aarch64-apple-ios-sim/release/librust_lib_flutter_rust_wallet.a" \
    "${RUST_DIR}/target/x86_64-apple-ios/release/librust_lib_flutter_rust_wallet.a" \
    -output "${SIMULATOR_FAT_DIR}/librust_lib_flutter_rust_wallet.a"

# Create xcframework
echo "Creating xcframework..."
xcodebuild -create-xcframework \
    -library "${RUST_DIR}/target/aarch64-apple-ios/release/librust_lib_flutter_rust_wallet.a" \
    -library "${SIMULATOR_FAT_DIR}/librust_lib_flutter_rust_wallet.a" \
    -output "${FRAMEWORKS_DIR}/${XCFRAMEWORK_NAME}.xcframework"

# Verify the xcframework
echo "Verifying xcframework..."
if [[ -d "${FRAMEWORKS_DIR}/${XCFRAMEWORK_NAME}.xcframework" ]]; then
    echo "xcframework created successfully at:"
    echo "  ${FRAMEWORKS_DIR}/${XCFRAMEWORK_NAME}.xcframework"
    echo ""
    echo "Architectures included:"
    for lib in $(find "${FRAMEWORKS_DIR}/${XCFRAMEWORK_NAME}.xcframework" -name "*.a"); do
        echo "  $(dirname $lib | xargs basename):"
        lipo -info "$lib" 2>/dev/null | sed 's/^/    /'
    done
else
    echo "Error: Failed to create xcframework"
    exit 1
fi

# Cleanup
rm -rf "${SIMULATOR_FAT_DIR}"

echo ""
echo "iOS Minotari library build complete!"
