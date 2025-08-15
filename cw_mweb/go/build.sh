export ANDROID_OUT=../android/src/main/jniLibs
export ANDROID_SDK="${HOME}/Library/Android/sdk"
export NDK_BIN="${ANDROID_SDK}/ndk/28.2.13676358/toolchains/llvm/prebuilt/darwin-x86_64/bin"

## Compile for x86_64 architecture and place the binary file in the android/src/main/jniLibs/x86_64 folder
#CGO_ENABLED=1 \
#GOOS=android \
#GOARCH=amd64 \
#CC=${NDK_BIN}/x86_64-linux-android21-clang \
#go build -buildmode=c-shared -o ${ANDROID_OUT}/x86_64/mweb.so .
#
## Compile for arm64 architecture and place the binary file in the android/src/main/jniLibs/arm64-v8a folder
#CGO_ENABLED=1 \
#GOOS=android \
#GOARCH=arm64 \
#CC=${NDK_BIN}/aarch64-linux-android21-clang \
#go build -buildmode=c-shared -o ${ANDROID_OUT}/arm64-v8a/mweb.so .


export GOOS=ios   # ios: ios, android: android
export GOARCH=arm64  # iPhone simulator: amd64
export SDK=iphoneos  # iPhone simulator: iphonesimulator
export CGO_ENABLED=1
export CGO_CFLAGS="-fembed-bitcode"

export SDK_PATH=`xcrun --sdk $SDK --show-sdk-path`
export CLANG=`xcrun --sdk $SDK --find clang`
# export CARCH="x86_64"  # if compiling for iPhone simulator
export CARCH="arm64"  # if compiling for iPhone
export CC_target="aarch64-apple-ios"
export CC="$(xcrun -f clang) -target $CC_target -mios-version-min=12 --sysroot $(xcrun --sdk iphoneos --show-sdk-path) -I $(xcrun --sdk iphoneos --show-sdk-path)"
go build -buildmode c-archive -trimpath -o MWebd.a mweb.go

write_info_plist() {
    framework_bundle="$1"
    framework_name="$2"
    target="$3"
    plist_path="${framework_bundle}/Info.plist"

    if [[ "x$target" = "xiossimulator" ]]; then
        platform="iPhoneSimulator"
        dtplatformname="iphonesimulator"
        dtsdkname="iphonesimulator17.4"
    else
        platform="iPhoneOS"
        dtplatformname="iphoneos"
        dtsdkname="iphoneos17.4"
    fi

    cat > "$plist_path" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>BuildMachineOSBuild</key>
  <string>23E224</string>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>${framework_name}</string>
  <key>CFBundleIdentifier</key>
  <string>com.fotolockr.${framework_name}</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>${framework_name}</string>
  <key>CFBundlePackageType</key>
  <string>FMWK</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0</string>
  <key>CFBundleSignature</key>
  <string>???</string>
  <key>CFBundleSupportedPlatforms</key>
  <array>
    <string>${platform}</string>
  </array>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>DTCompiler</key>
  <string>com.apple.compilers.llvm.clang.1_0</string>
  <key>DTPlatformBuild</key>
  <string>21E210</string>
  <key>DTPlatformName</key>
  <string>${dtplatformname}</string>
  <key>DTPlatformVersion</key>
  <string>17.4</string>
  <key>DTSDKBuild</key>
  <string>21E210</string>
  <key>DTSDKName</key>
  <string>${dtsdkname}</string>
  <key>DTXcode</key>
  <string>1530</string>
  <key>DTXcodeBuild</key>
  <string>15E204a</string>
  <key>MinimumOSVersion</key>
  <string>16.0</string>
  <key>UIDeviceFamily</key>
  <array>
    <integer>1</integer>
    <integer>2</integer>
  </array>
  <key>UIRequiredDeviceCapabilities</key>
  <array>
    <string>arm64</string>
  </array>
</dict>
</plist>
EOF
    plutil -convert binary1 "$plist_path"
}

create_framework() {
    framework_name="Mwebd"
    target="$2"
    out_dir="$3"

    echo "Creating ${framework_name}.framework for target ${target} in ${out_dir}..."

    framework_bundle="${out_dir}/${framework_name}.framework"

    rm -rf "$framework_bundle"
    mkdir -p "$framework_bundle"

    input_dylib="MWebd.a"
    if [[ ! -f "$input_dylib" ]]; then
        echo "Error: Input dylib not found: $input_dylib"
        exit 1
    fi

    lipo -create "$input_dylib" -output "${framework_bundle}/${framework_name}"
    echo "Created binary: ${framework_bundle}/${framework_name}"

    write_info_plist "$framework_bundle" "$framework_name" "$target"
}

create_framework "" "ios" "."
xcodebuild -create-xcframework -framework Mwebd.framework -output "Mwebd.xcframework"
