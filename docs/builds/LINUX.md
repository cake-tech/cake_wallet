# Building Cake Wallet for Linux

## Requirements and Setup

As we use Docker with a custom Dockerfile to build Cake Wallet, the only dependency for building Cake on your local host is the Docker Engine.

You can find the latest instructions for installing Docker on your given OS on the official website:

- <https://docs.docker.com/engine/install/>

NOTE: If building on a Mac with an M-series CPU (arm64), you may encounter segmentation faults when building. If you do, simply retry the build.

## Building Cake Wallet or Monero.com

### Using the pre-built builder image

In order to build the latest version of Cake Wallet, simply run the following:

```bash
git clone --branch main https://github.com/cake-tech/cake_wallet.git
# NOTE: Replace `main` with the latest release tag available at https://github.com/cake-tech/cake_wallet/releases/latest.
cd cake_wallet
# docker build -t ghcr.io/cake-tech/cake_wallet:debian13-flutter3.32.0-ndkr28-go1.24.1-ruststablenightly . # Uncomment to build the docker image yourself instead of pulling it from the registry
docker run --privileged -v$(pwd):$(pwd) -w $(pwd) -i --rm ghcr.io/cake-tech/cake_wallet:debian13-flutter3.32.0-ndkr28-go1.24.1-ruststablenightly bash -x << EOF
set -x -e
pushd scripts
    ./gen_android_manifest.sh
popd
pushd scripts/linux
    source ./app_env.sh cakewallet
    # source ./app_env.sh monero.com # Uncomment this line to build monero.com
    ./app_config.sh
    ./build_monero_all.sh
popd
flutter clean
./model_generator.sh
dart run tool/generate_localization.dart
dart run tool/generate_new_secrets.dart
flutter build linux
cp -r build/linux/x64 build/linux/current
# use line below if you are building on arm64
# cp -r build/linux/arm64 build/linux/current
# If you want to build flatpak you need --privileged flag
flatpak-builder --force-clean flatpak-build com.cakewallet.CakeWallet.yml
flatpak build-export export flatpak-build
flatpak build-bundle export build/linux/current/cake_wallet.flatpak com.cakewallet.CakeWallet
EOF
```

You should see the command complete with similar output:

```bash
+ dart run tool/generate_localization.dart
+ dart run tool/generate_new_secrets.dart
+ flutter build linux

Building Linux application...                                   
✓ Built build/linux/x64/release/bundle/cake_wallet
```

Final builds can be found in `build/linux/current/release/bundle/` as seen above.


To install the newly built Flatpak, run:

```bash
flatpak --user install build/linux/current/cake_wallet.flatpak
```
