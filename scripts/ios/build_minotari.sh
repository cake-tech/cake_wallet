#!/bin/bash
#
# Build Minotari Rust library for iOS
# Creates an xcframework with dynamic frameworks supporting both device and simulator
#

set -e -x
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

CW_ROOT=$(realpath ../..);
CW_MINOTARI_DIR="${CW_ROOT}/cw_minotari"
RUST_DIR="${CW_MINOTARI_DIR}/rust"
IOS_OUT="${CW_MINOTARI_DIR}/ios"
FRAMEWORKS_DIR="${IOS_OUT}/Frameworks"
TMP_DIR="${RUST_DIR}/target/framework-temp"

# Library name must match what Flutter Rust Bridge expects (from frb_generated.dart stem)
LIB_NAME="rust_lib_flutter_rust_wallet"
FRAMEWORK_NAME="${LIB_NAME}"

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
rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cd "$RUST_DIR"

# Clean previous builds
rm -rf "${FRAMEWORKS_DIR}/${FRAMEWORK_NAME}.xcframework"
rm -rf "${FRAMEWORKS_DIR}/RustMinotari.xcframework"

# Build for iOS device (arm64)
echo "Building for iOS device (aarch64-apple-ios)..."
cargo build --release --target aarch64-apple-ios

# Build for iOS simulator (arm64 - Apple Silicon)
echo "Building for iOS simulator arm64 (aarch64-apple-ios-sim)..."
cargo build --release --target aarch64-apple-ios-sim

# Build for iOS simulator (x86_64 - Intel Macs)
echo "Building for iOS simulator x86_64 (x86_64-apple-ios)..."
cargo build --release --target x86_64-apple-ios

# Function to write Info.plist for a framework bundle
write_info_plist() {
    local framework_bundle="$1"
    local framework_name="$2"
    local target="$3"
    local plist_path="${framework_bundle}/Info.plist"

    local platform min_os_version

    if [[ "$target" == "ios-simulator" ]]; then
        platform="iPhoneSimulator"
        min_os_version="12.0"
    elif [[ "$target" == "ios" ]]; then
        platform="iPhoneOS"
        min_os_version="12.0"
    else
        echo "Unknown target: $target"
        exit 1
    fi

    cat > "$plist_path" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${framework_name}</string>
    <key>CFBundleIdentifier</key>
    <string>com.cakewallet.minotari</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${framework_name}</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleSupportedPlatforms</key>
    <array>
        <string>${platform}</string>
    </array>
    <key>DTCompiler</key>
    <string>com.apple.compilers.llvm.clang.1_0</string>
    <key>MinimumOSVersion</key>
    <string>${min_os_version}</string>
    <key>UIDeviceFamily</key>
    <array>
        <integer>1</integer>
        <integer>2</integer>
    </array>
</dict>
</plist>
EOF
}

# Function to create a dynamic framework from a static archive
# Convert static .a to dynamic .framework using clang
create_framework() {
    local archive_path="$1"
    local framework_name="$2"
    local target="$3"
    local out_dir="$4"
    local arch="$5"

    echo "Creating ${framework_name}.framework for target ${target} (${arch}) in ${out_dir}..."

    local framework_bundle="${out_dir}/${framework_name}.framework"

    rm -rf "$framework_bundle"
    mkdir -p "$framework_bundle"

    if [[ ! -f "$archive_path" ]]; then
        echo "Error: Input archive not found: $archive_path"
        exit 1
    fi

    # Create a temp directory for extracting object files
    local temp_dir="${TMP_DIR}/temp_${target}_${arch}"
    mkdir -p "$temp_dir"

    pushd "$temp_dir"
      # Extract object files from static archive
      ar x "$archive_path"

      # Link object files into a dynamic library
      local sdk
      local min_os_flag
      if [[ "$target" == "ios" ]]; then
          sdk="iphoneos"
          min_os_flag="-mios-version-min=12"
      else
          sdk="iphonesimulator"
          min_os_flag="-mios-simulator-version-min=12"
      fi
      xcrun -sdk "${sdk}" clang -dynamiclib -arch "${arch}" "${min_os_flag}" \
          -install_name "@rpath/${framework_name}.framework/${framework_name}" \
          -framework CoreFoundation -framework Security -lresolv -lc++ -lz -lsqlite3 \
          -o "${framework_bundle}/${framework_name}" ./*.o
    popd

    echo "Created binary: ${framework_bundle}/${framework_name}"

    # Write Info.plist
    write_info_plist "$framework_bundle" "$framework_name" "$target"

    echo "Framework created: ${framework_bundle}"
}

# Function to create xcframework from framework bundles
create_xcframework() {
    local framework_name="$1"
    local xcframework_output="$2"
    shift 2
    local frameworks=("$@")

    echo "Creating ${xcframework_output} by bundling:"
    for fw in "${frameworks[@]}"; do
        echo "  Framework: ${fw}"
    done

    local xcodebuild_args=()
    for fw in "${frameworks[@]}"; do
        xcodebuild_args+=("-framework" "$fw")
    done

    rm -rf "$xcframework_output"
    xcodebuild -create-xcframework "${xcodebuild_args[@]}" -output "$xcframework_output"

    echo "Created XCFramework: ${xcframework_output}"
}

echo "Creating framework bundles from static archives..."

# Define paths
IOS_DEVICE_OUT="${TMP_DIR}/ios_device"
IOS_SIMULATOR_ARM64_OUT="${TMP_DIR}/ios_simulator_arm64"
IOS_SIMULATOR_X86_64_OUT="${TMP_DIR}/ios_simulator_x86_64"

mkdir -p "$IOS_DEVICE_OUT" "$IOS_SIMULATOR_ARM64_OUT" "$IOS_SIMULATOR_X86_64_OUT"

# Static archives from Rust cargo build
DEVICE_ARCHIVE="${RUST_DIR}/target/aarch64-apple-ios/release/lib${LIB_NAME}.a"
SIMULATOR_ARM64_ARCHIVE="${RUST_DIR}/target/aarch64-apple-ios-sim/release/lib${LIB_NAME}.a"
SIMULATOR_X86_64_ARCHIVE="${RUST_DIR}/target/x86_64-apple-ios/release/lib${LIB_NAME}.a"

# Create individual frameworks
create_framework "$DEVICE_ARCHIVE" "$FRAMEWORK_NAME" "ios" "$IOS_DEVICE_OUT" "arm64"
create_framework "$SIMULATOR_ARM64_ARCHIVE" "$FRAMEWORK_NAME" "ios-simulator" "$IOS_SIMULATOR_ARM64_OUT" "arm64"
create_framework "$SIMULATOR_X86_64_ARCHIVE" "$FRAMEWORK_NAME" "ios-simulator" "$IOS_SIMULATOR_X86_64_OUT" "x86_64"

# Create universal simulator framework (arm64 + x86_64)
IOS_SIMULATOR_UNIVERSAL_OUT="${TMP_DIR}/ios_simulator_universal"
mkdir -p "$IOS_SIMULATOR_UNIVERSAL_OUT"

SIMULATOR_UNIVERSAL_FRAMEWORK="${IOS_SIMULATOR_UNIVERSAL_OUT}/${FRAMEWORK_NAME}.framework"
mkdir -p "$SIMULATOR_UNIVERSAL_FRAMEWORK"

lipo -create \
    "${IOS_SIMULATOR_ARM64_OUT}/${FRAMEWORK_NAME}.framework/${FRAMEWORK_NAME}" \
    "${IOS_SIMULATOR_X86_64_OUT}/${FRAMEWORK_NAME}.framework/${FRAMEWORK_NAME}" \
    -output "${SIMULATOR_UNIVERSAL_FRAMEWORK}/${FRAMEWORK_NAME}"

echo "Created universal simulator binary: ${SIMULATOR_UNIVERSAL_FRAMEWORK}/${FRAMEWORK_NAME}"

# Copy Info.plist from arm64 simulator framework
cp "${IOS_SIMULATOR_ARM64_OUT}/${FRAMEWORK_NAME}.framework/Info.plist" "${SIMULATOR_UNIVERSAL_FRAMEWORK}/"

# Create final xcframework
IOS_DEVICE_FRAMEWORK="${IOS_DEVICE_OUT}/${FRAMEWORK_NAME}.framework"
IOS_SIMULATOR_FRAMEWORK="${SIMULATOR_UNIVERSAL_FRAMEWORK}"

XCFRAMEWORK_OUTPUT="${FRAMEWORKS_DIR}/${FRAMEWORK_NAME}.xcframework"
create_xcframework "$FRAMEWORK_NAME" "$XCFRAMEWORK_OUTPUT" "$IOS_DEVICE_FRAMEWORK" "$IOS_SIMULATOR_FRAMEWORK"

# Verify the xcframework
echo ""
echo "Verifying xcframework..."
if [[ -d "${XCFRAMEWORK_OUTPUT}" ]]; then
    echo "xcframework created successfully at:"
    echo "  ${XCFRAMEWORK_OUTPUT}"
    echo ""
    echo "Framework contents:"
    find "${XCFRAMEWORK_OUTPUT}" -name "${FRAMEWORK_NAME}" -type f | while read -r binary; do
        echo "  $(dirname "$binary" | xargs basename):"
        lipo -info "$binary" 2>/dev/null | sed 's/^/    /'
        file "$binary" | sed 's/^/    /'
    done
else
    echo "Error: Failed to create xcframework"
    exit 1
fi

# Cleanup
rm -rf "${TMP_DIR}"

echo ""
echo "iOS Minotari library build complete for ${TARI_NETWORK}!"
