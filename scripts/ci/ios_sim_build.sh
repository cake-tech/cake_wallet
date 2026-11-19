#!/bin/bash
# Simulator build of the app for the iOS e2e lane (.github/workflows/e2e_ios.yml).
# It needs no secrets: API keys are placeholders, so providers that need one are unavailable.
#
# Usage: scripts/ci/ios_sim_build.sh <path-to-cake_wallet>
# Produces: build/ios/iphonesimulator/Runner.app (flutter --simulator --debug)
set -euo pipefail

WALLET="${1:?usage: ios_sim_build.sh <path-to-cake_wallet>}"
cd "$WALLET"

# A freshly cloned Flutter SDK has no engine packages (sky_engine) until a flutter command
# fetches them; the `dart run` steps below would fail to resolve without this.
flutter precache --ios

# 0. torch_dart: cw_core depends on the Dart package at scripts/torch_dart. Clone it at the
#    pinned commit, then take the prebuilt LibTorch.xcframework from the upstream release:
#    it carries the ios-arm64-simulator slice, which the app's own CI images omit, and
#    building Tor from source on macOS is not workable.
TORCH_RELEASE="v1.0.18"
./scripts/prepare_torch.sh
if [[ ! -d scripts/torch_dart/ios/LibTorch.xcframework/ios-arm64-simulator ]]; then
  TMPT="$(mktemp -d)"
  curl -fsSL "https://github.com/MrCyjaneK/torch_dart/releases/download/${TORCH_RELEASE}/torch_dart-${TORCH_RELEASE}.tar.gz" -o "$TMPT/torch.tgz"
  mkdir -p "$TMPT/x" scripts/torch_dart/ios
  tar -xzf "$TMPT/torch.tgz" -C "$TMPT/x" ./ios/LibTorch.xcframework
  rm -rf scripts/torch_dart/ios/LibTorch.xcframework
  mv "$TMPT/x/ios/LibTorch.xcframework" scripts/torch_dart/ios/LibTorch.xcframework
  rm -rf "$TMPT"
fi
test -d scripts/torch_dart/ios/LibTorch.xcframework/ios-arm64-simulator

# 1. monero_c source at the pinned commit (with patches applied).
./scripts/prepare_moneroc.sh

# 2. Prebuilt monero_c bundle (device + simulator dylibs), then the xcframeworks.
#    The zip's top directory is the tag, which is the layout gen_framework.sh reads
#    when MONEROC_TAG names it. Coins the bundle lacks are dropped from the Xcode
#    project the way the app's own CI does (their wallets fail to open; the build passes).
MONEROC_TAG="v0.18.4.6-RC2"
BUNDLE_URL="https://github.com/MrCyjaneK/monero_c/releases/download/${MONEROC_TAG}/release-bundle.zip"
TMPB="$(mktemp -d)"
if [[ ! -d "scripts/monero_c/release/${MONEROC_TAG}/aarch64-apple-ios-simulator" ]]; then
  curl -fsSL "$BUNDLE_URL" -o "$TMPB/release-bundle.zip"
  rm -rf "scripts/monero_c/release/${MONEROC_TAG}"
  mkdir -p scripts/monero_c/release
  unzip -qo "$TMPB/release-bundle.zip" -d scripts/monero_c/release
fi
test -d "scripts/monero_c/release/${MONEROC_TAG}/aarch64-apple-ios-simulator"
( cd scripts/ios && MONEROC_TAG="$MONEROC_TAG" ./gen_framework.sh )
test -d ios/MoneroWallet.xcframework
for fw in WowneroWallet ZanoWallet; do
  [[ -d "ios/${fw}.xcframework" ]] || sed -i '' -e "/${fw}\.xcframework/d" ios/Runner.xcodeproj/project.pbxproj
done

# 3. cw_decred for the SIMULATOR: the script hardcodes -target arm64-apple-ios
#    and the iphoneos SDK; patch a copy (script itself stays untouched).
sed -e 's/arm64-apple-ios/arm64-apple-ios-simulator/g' \
    -e 's/--sdk iphoneos/--sdk iphonesimulator/g' \
    scripts/ios/build_decred.sh > scripts/ios/.build_decred_sim.sh
( cd scripts/ios && bash .build_decred_sim.sh )
rm -f scripts/ios/.build_decred_sim.sh

# 4. cw_mweb for the SIMULATOR (supports it natively); then fix the ffigen
#    config the script's sed misses (pattern looks for mweb.h, the config says
#    libmweb.h) and regenerate bindings from the XCFramework header, restoring
#    the config afterwards.
( cd scripts/ios && ./build_mwebd.sh --install )
( cd cw_mweb
  cp ffigen_config.yaml ffigen_config.yaml.ci.bak
  sed -i '' -e "s|android/src/main/jniLibs/arm64-v8a/libmweb.h|ios/Mwebd.xcframework/ios-arm64/Mwebd.framework/Headers/Mwebd.h|" ffigen_config.yaml
  dart run ffigen --config ffigen_config.yaml
  mv ffigen_config.yaml.ci.bak ffigen_config.yaml )

# 5. Configure the app the way the app's CI does: reown sources, placeholder API
#    secrets (the lane has none; providers that need a key are simply unavailable),
#    pubspec + per-coin configuration, generated code, localization, graphics.
./scripts/prepare_reown.sh
for p in cw_bitcoin cw_evm cw_solana cw_core cw_nano cw_tron; do touch "$p/lib/.secrets.g.dart"; done
( cd scripts/ios
  source ./app_env.sh cakewallet
  ./app_config.sh )
dart run tool/generate_new_secrets.dart
add_secret() { grep -q "const $2 " "$1" 2>/dev/null || printf "const %s = '';\n" "$2" >> "$1"; }
for k in polygonScanApiKey etherScanApiKey moralisApiKey nowNodesApiKey blinkApiKey alchemyApiKey; do add_secret cw_evm/lib/.secrets.g.dart "$k"; done
for k in ankrApiKey chainStackApiKey moralisApiKey; do add_secret cw_solana/lib/.secrets.g.dart "$k"; done
for k in nano2ApiKey nanoNowNodesApiKey; do add_secret cw_nano/lib/.secrets.g.dart "$k"; done
for k in tronGridApiKey tronNowNodesApiKey; do add_secret cw_tron/lib/.secrets.g.dart "$k"; done
add_secret cw_bitcoin/lib/.secrets.g.dart breezApiKey
flutter pub get
./model_generator.sh
dart run tool/generate_localization.dart
./compile_graphics.sh

# 6. CocoaPods: homebrew's pod is broken (brew ruby 4.0 vs cellar gems) —
#    install into the user gem dir like P0-e did.
if ! command -v pod >/dev/null 2>&1 || ! pod --version >/dev/null 2>&1; then
  gem install --user-install cocoapods
fi
export PATH="$PATH:$(ruby -e 'print Gem.user_dir' 2>/dev/null)/bin"
cd ios && pod install && cd ..

# 7. The simulator build itself.
flutter build ios --simulator --debug
echo "simulator app: build/ios/iphonesimulator/Runner.app"
