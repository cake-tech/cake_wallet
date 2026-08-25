#!/bin/bash
# Master build script for PIVX Sapling native library
# Builds for all platforms

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== PIVX Sapling Native Library Builder ===${NC}"
echo ""

# Parse arguments
BUILD_IOS=false
BUILD_ANDROID=false
BUILD_MACOS=false
BUILD_LINUX=false
BUILD_ALL=true

while [[ $# -gt 0 ]]; do
    case $1 in
        --ios)
            BUILD_IOS=true
            BUILD_ALL=false
            shift
            ;;
        --android)
            BUILD_ANDROID=true
            BUILD_ALL=false
            shift
            ;;
        --macos)
            BUILD_MACOS=true
            BUILD_ALL=false
            shift
            ;;
        --linux)
            BUILD_LINUX=true
            BUILD_ALL=false
            shift
            ;;
        --help)
            echo "Usage: $0 [--ios] [--android] [--macos] [--linux]"
            echo ""
            echo "Options:"
            echo "  --ios      Build for iOS (device and simulator)"
            echo "  --android  Build for Android (all architectures)"
            echo "  --macos    Build for macOS (universal binary)"
            echo "  --linux    Build for Linux"
            echo ""
            echo "If no options are specified, builds for all platforms."
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

if [ "$BUILD_ALL" = true ]; then
    BUILD_IOS=true
    BUILD_ANDROID=true
    BUILD_MACOS=true
    BUILD_LINUX=true
fi

# Detect platform
if [[ "$OSTYPE" == "darwin"* ]]; then
    HOST_PLATFORM="macos"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    HOST_PLATFORM="linux"
else
    HOST_PLATFORM="unknown"
fi

echo -e "${YELLOW}Host platform: $HOST_PLATFORM${NC}"
echo ""

# Build iOS (macOS only)
if [ "$BUILD_IOS" = true ]; then
    if [ "$HOST_PLATFORM" = "macos" ]; then
        echo -e "${YELLOW}Building for iOS...${NC}"
        bash "$SCRIPT_DIR/build_ios.sh"
        echo ""
    else
        echo -e "${YELLOW}Skipping iOS build (requires macOS)${NC}"
    fi
fi

# Build Android
if [ "$BUILD_ANDROID" = true ]; then
    echo -e "${YELLOW}Building for Android...${NC}"
    bash "$SCRIPT_DIR/build_android.sh"
    echo ""
fi

# Build macOS (macOS only)
if [ "$BUILD_MACOS" = true ]; then
    if [ "$HOST_PLATFORM" = "macos" ]; then
        echo -e "${YELLOW}Building for macOS...${NC}"
        bash "$SCRIPT_DIR/build_macos.sh"
        echo ""
    else
        echo -e "${YELLOW}Skipping macOS build (requires macOS)${NC}"
    fi
fi

# Build Linux
if [ "$BUILD_LINUX" = true ]; then
    if [ "$HOST_PLATFORM" = "linux" ]; then
        echo -e "${YELLOW}Building for Linux...${NC}"
        bash "$SCRIPT_DIR/build_linux.sh"
        echo ""
    else
        echo -e "${YELLOW}Skipping Linux build (requires Linux)${NC}"
    fi
fi

echo -e "${GREEN}=== Build Complete ===${NC}"
