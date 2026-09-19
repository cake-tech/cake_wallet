# PIVX Sapling Native Library for macOS

This directory contains the native PIVX Sapling library for macOS.

## Building

Run the build script from the cw_pivx directory:

```bash
./scripts/build_macos.sh
```

This will:
1. Build the Rust library for macOS arm64 (Apple Silicon)
2. Build for macOS x86_64 (Intel)
3. Create a universal binary using lipo
4. Copy to this directory

## Contents

After building:
- `libcw_pivx_sapling.a` - Universal static library (arm64 + x86_64)
- `cw_pivx_sapling.h` - C header file

## Requirements

- Rust (with cargo)
- rustup targets: `aarch64-apple-darwin`, `x86_64-apple-darwin`
- Xcode Command Line Tools (for lipo)
