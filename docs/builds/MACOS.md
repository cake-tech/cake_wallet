# Building Cake Wallet for macOS

## Requirements and Setup

The following are the system requirements to build Cake Wallet for your macOS device.

```txt
macOS >= 14.0 
Xcode 15.3
Flutter 3.24.4
```

### 1. Installing dependencies

For installing dependency tools you can use brew [Install brew](https://brew.sh).

You may easily install them on your build system with the following command:

```zsh
brew install cmake xz automake autoconf libtool boost@1.76 zmq cocoapods
brew link boost@1.76
```

### 2. Installing Xcode

Download and install the latest version of [Xcode](https://developer.apple.com/xcode/) from macOS App Store.

### 3. Installing Flutter

Install Flutter, specifically version `3.24.4` by following the [official docs](https://docs.flutter.dev/get-started/install/macos/desktop?tab=download).

NOTE: as `3.24.4` is not the latest version, you'll need to download it from <https://docs.flutter.dev/release/archive> instead of the link in the docs above.

### 4. Installing Rust

Install Rust from the [rustup.rs](https://rustup.rs/) website.

```zsh
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

### 5. Verify Flutter and Xcode installation

Verify that Flutter and Xcode have been correctly installed on your system with the following command:

`flutter doctor`

The output of this command should appear like this, indicating successful installations. If there are problems with your installation, they **must** be corrected before proceeding.

```zsh
Doctor summary (to see all details, run flutter doctor -v):
[✓] Flutter (Channel stable, 3.24.4, on macOS 14.x.x)
[✓] Xcode - develop for iOS and macOS (Xcode 15.3)
```

### 6. Acquiring the Cake Wallet source code

Download the latest release tag of Cake Wallet and enter the source code directory:

```zsh
git clone https://github.com/cake-tech/cake_wallet.git --branch v4.23.0
cd cake_wallet/scripts/macos/
```

NOTE: Replace `v4.23.0` with the latest release tag available at <https://github.com/cake-tech/cake_wallet/releases/latest>.

### 7. Setup and build Cake Wallet from source

We need to generate project settings like app name, app icon, package name, etc, including what specific variant of the app we want to build.

To build Cake Wallet from source, run the following:

```zsh
source ./app_env.sh cakewallet
```

For Monero.com, instead do:

```zsh
source ./app_env.sh monero.com
```

Then run the configuration script to setup app name, app icon, etc:

```zsh
./app_config.sh
```

Build the necessary libraries and their dependencies:

```zsh
./build_monero_all.sh
```

NOTE: This step will take quite a while, so be sure you grab a cup of coffee or a good book!

### Optional: building universal libraries

If you have the need to build universal monero libraries, then it will require additional steps. For instance, to build universal monero libraries on a Mac with Apple Silicon (arm64):

Install Rosetta:

```zsh
softwareupdate --install-rosetta
```

Install [Brew](https://brew.sh/) with rosetta:

```zsh
arch -x86_64 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Install dependencies for build monero wallet lib for x86_64 with brew and link installed boost:

```zsh
arch -x86_64 /usr/local/bin/brew install automake autoconf libtool openssl boost@1.76 zmq
arch -x86_64 /usr/local/bin/brew link boost@1.76
```

Run building script with additional argument:

```zsh
./build_monero_all.sh universal
```

If you need to build monero wallet libraries only for x86_64 on arm64 mac, then use the steps above and run the build script using rosetta without arguments:

```zsh
arch -x86_64 ./build_monero_all.sh`
```

### 8. Prepare Flutter

Change back to the root directory of the Cake Wallet source code and install Flutter package dependencies:

```zsh
cd ../../
flutter pub get
```

Generate secrets as placeholders for official API keys etc. along with localization files and mobx models:

```zsh
dart run tool/generate_new_secrets.dart
./configure_cake_wallet.sh macos
```

### 9. Build

```zsh
flutter build macos --release
```

Then you can open `macos/Runner.xcworkspace` with Xcode to archive the application.

Ff you want to run on a connected device, simply run:

```zsh
flutter run --release
```
