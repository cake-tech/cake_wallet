#!/bin/bash

set -e -x

if [[ "$1" == "--install" ]]; then
  # install go > 1.24:
  brew install go
  export PATH=$PATH:~/go/bin
fi

BASE_DIR="$(pwd)"
MWEB_GO_DIR="${BASE_DIR}/../../cw_mweb/go"
IOS_OUTPUT_DIR="${BASE_DIR}/../../cw_mweb/ios"
TMP_DIR="${BASE_DIR}/tmp_mweb_frameworks"
FRAMEWORK_NAME="Mwebd"

rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"

mkdir -p "$IOS_OUTPUT_DIR"

write_info_plist() {
    local framework_bundle="$1"
    local framework_name="$2"
    local target="$3"
    local arch="$4"
    local plist_path="${framework_bundle}/Info.plist"

    local platform min_os_version dtplatformname dtsdkname

    if [[ "$target" == "ios-simulator" ]]; then
        platform="iPhoneSimulator"
        dtplatformname="iphonesimulator"
        dtsdkname="iphonesimulator17.4"
        min_os_version="12.0"
    elif [[ "$target" == "ios" ]]; then
        platform="iPhoneOS"
        dtplatformname="iphoneos"
        dtsdkname="iphoneos17.4"
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
    <key>BuildMachineOSBuild</key>
    <string>23F79</string>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>${framework_name}</string>
    <key>CFBundleIdentifier</key>
    <string>com.cakewallet.${framework_name}</string>
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
    <key>DTPlatformName</key>
    <string>${dtplatformname}</string>
    <key>DTPlatformVersion</key>
    <string>17.4</string>
    <key>DTSDKBuild</key>
    <string>21E213</string>
    <key>DTSDKName</key>
    <string>${dtsdkname}</string>
    <key>DTSDKVersion</key>
    <string>17.4</string>
    <key>DTXcode</key>
    <string>1530</string>
    <key>DTXcodeBuild</key>
    <string>15E204a</string>
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

build_go_library() {
    local goos="$1"
    local goarch="$2"
    local cc_target="$3"
    local sdk="$4"
    local output_file="$5"
    
    echo "Building Go library for ${goos}/${goarch} with target ${cc_target}..."
    
    cd "$MWEB_GO_DIR"
    
    export GOOS="$goos"
    export GOARCH="$goarch"
    export CGO_ENABLED=1
    export CGO_CFLAGS="-fembed-bitcode"
    
    if [[ "$sdk" == "iphoneos" ]]; then
        export CC="$(xcrun -f clang) -target $cc_target -mios-version-min=12 --sysroot $(xcrun --sdk iphoneos --show-sdk-path)"
    else
        export CC="$(xcrun -f clang) -target $cc_target -mios-simulator-version-min=12 --sysroot $(xcrun --sdk iphonesimulator --show-sdk-path)"
    fi
    
    go build -buildmode=c-archive -trimpath -o "$output_file" mweb.go
    
    echo "Built: $output_file"
    cd - > /dev/null
}

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

    local temp_dir="${TMP_DIR}/temp_${arch}"
    mkdir -p "$temp_dir"
    
    pushd "$temp_dir"
      ar x "$archive_path"
      
      if [[ "$target" == "ios" ]]; then
          xcrun -sdk iphoneos clang -dynamiclib -arch "${arch}" -mios-version-min=12 \
              -install_name "@rpath/${framework_name}.framework/${framework_name}" \
              -framework CoreFoundation -framework Security -lresolv \
              -o "${framework_bundle}/${framework_name}" ./*.o
      else
          xcrun -sdk iphonesimulator clang -dynamiclib -arch "${arch}" -mios-simulator-version-min=12 \
              -install_name "@rpath/${framework_name}.framework/${framework_name}" \
              -framework CoreFoundation -framework Security -lresolv \
              -o "${framework_bundle}/${framework_name}" ./*.o
      fi
    popd
    
    echo "Created binary: ${framework_bundle}/${framework_name}"

    write_info_plist "$framework_bundle" "$framework_name" "$target" "$arch"
    
    mkdir -p "${framework_bundle}/Headers"
    local header_file="${archive_path%.a}.h"
    if [[ -f "$header_file" ]]; then
        cp "$header_file" "${framework_bundle}/Headers/${framework_name}.h"
        echo "Copied header: ${framework_bundle}/Headers/${framework_name}.h"
    fi
    
    echo "Framework created: ${framework_bundle}"
}

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

echo "Building MWEB XCFramework for iOS..."

IOS_DEVICE_OUT="${TMP_DIR}/ios_device"
IOS_SIMULATOR_ARM64_OUT="${TMP_DIR}/ios_simulator_arm64"
IOS_SIMULATOR_X86_64_OUT="${TMP_DIR}/ios_simulator_x86_64"

mkdir -p "$IOS_DEVICE_OUT" "$IOS_SIMULATOR_ARM64_OUT" "$IOS_SIMULATOR_X86_64_OUT"

IOS_DEVICE_ARCHIVE="${TMP_DIR}/${FRAMEWORK_NAME}_device.a"
IOS_SIMULATOR_ARM64_ARCHIVE="${TMP_DIR}/${FRAMEWORK_NAME}_sim_arm64.a"
IOS_SIMULATOR_X86_64_ARCHIVE="${TMP_DIR}/${FRAMEWORK_NAME}_sim_x86_64.a"

build_go_library "ios" "arm64" "aarch64-apple-ios" "iphoneos" "$IOS_DEVICE_ARCHIVE"
build_go_library "ios" "arm64" "aarch64-apple-ios-simulator" "iphonesimulator" "$IOS_SIMULATOR_ARM64_ARCHIVE"
build_go_library "ios" "amd64" "x86_64-apple-ios-simulator" "iphonesimulator" "$IOS_SIMULATOR_X86_64_ARCHIVE"

create_framework "$IOS_DEVICE_ARCHIVE" "$FRAMEWORK_NAME" "ios" "$IOS_DEVICE_OUT" "arm64"
create_framework "$IOS_SIMULATOR_ARM64_ARCHIVE" "$FRAMEWORK_NAME" "ios-simulator" "$IOS_SIMULATOR_ARM64_OUT" "arm64"
create_framework "$IOS_SIMULATOR_X86_64_ARCHIVE" "$FRAMEWORK_NAME" "ios-simulator" "$IOS_SIMULATOR_X86_64_OUT" "x86_64"

IOS_SIMULATOR_UNIVERSAL_OUT="${TMP_DIR}/ios_simulator_universal"
mkdir -p "$IOS_SIMULATOR_UNIVERSAL_OUT"

SIMULATOR_UNIVERSAL_FRAMEWORK="${IOS_SIMULATOR_UNIVERSAL_OUT}/${FRAMEWORK_NAME}.framework"
mkdir -p "$SIMULATOR_UNIVERSAL_FRAMEWORK"

lipo -create \
    "${IOS_SIMULATOR_ARM64_OUT}/${FRAMEWORK_NAME}.framework/${FRAMEWORK_NAME}" \
    "${IOS_SIMULATOR_X86_64_OUT}/${FRAMEWORK_NAME}.framework/${FRAMEWORK_NAME}" \
    -output "${SIMULATOR_UNIVERSAL_FRAMEWORK}/${FRAMEWORK_NAME}"

echo "Created universal simulator binary: ${SIMULATOR_UNIVERSAL_FRAMEWORK}/${FRAMEWORK_NAME}"

cp -r "${IOS_SIMULATOR_ARM64_OUT}/${FRAMEWORK_NAME}.framework/Info.plist" "${SIMULATOR_UNIVERSAL_FRAMEWORK}/"
cp -r "${IOS_SIMULATOR_ARM64_OUT}/${FRAMEWORK_NAME}.framework/Headers" "${SIMULATOR_UNIVERSAL_FRAMEWORK}/"

IOS_DEVICE_FRAMEWORK="${IOS_DEVICE_OUT}/${FRAMEWORK_NAME}.framework"
IOS_SIMULATOR_FRAMEWORK="${SIMULATOR_UNIVERSAL_FRAMEWORK}"

IOS_XCFRAMEWORK="${IOS_OUTPUT_DIR}/${FRAMEWORK_NAME}.xcframework"
create_xcframework "$FRAMEWORK_NAME" "$IOS_XCFRAMEWORK" "$IOS_DEVICE_FRAMEWORK" "$IOS_SIMULATOR_FRAMEWORK"

echo ""
echo "XCFramework created successfully:"
echo "   iOS XCFramework: ${IOS_XCFRAMEWORK}"
echo ""

FFIGEN_CONFIG="${BASE_DIR}/../../cw_mweb/ffigen_config.yaml"
if [[ -f "$FFIGEN_CONFIG" ]]; then
    echo "Updating ffigen configuration..."
    sed -i.bak "s|android/src/main/jniLibs/arm64-v8a/mweb.h|ios/${FRAMEWORK_NAME}.xcframework/ios-arm64/${FRAMEWORK_NAME}.framework/Headers/${FRAMEWORK_NAME}.h|g" "$FFIGEN_CONFIG"
    mv "$FFIGEN_CONFIG.bak" "$FFIGEN_CONFIG"
    echo "Updated ffigen config to use XCFramework header"
fi

cd "${BASE_DIR}/../../cw_mweb"
echo "Generating Dart FFI bindings..."
dart run ffigen --config ffigen_config.yaml

echo "Build completed successfully!"

rm -rf "$TMP_DIR"
echo "Temporary files cleaned up."