# PIVX Sapling XCFramework

This directory contains the native PIVX Sapling library as an XCFramework.

## Building

Run the build script from the cw_pivx directory:

```bash
./scripts/build_ios.sh
```

This will:
1. Build the Rust library for iOS device (arm64)
2. Build for iOS simulator (arm64, x86_64)
3. Create a universal XCFramework
4. Generate the C header

## Contents

After building:
- `cw_pivx_sapling.xcframework/` - Universal framework for iOS device and simulators
  - `ios-arm64/` - Device slice
  - `ios-arm64_x86_64-simulator/` - Simulator slice

## Requirements

- Rust (with cargo)
- rustup targets: `aarch64-apple-ios`, `aarch64-apple-ios-sim`, `x86_64-apple-ios`
- Xcode Command Line Tools (for lipo, xcodebuild)
- cbindgen (`cargo install cbindgen`)
