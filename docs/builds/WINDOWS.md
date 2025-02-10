# Building Cake Wallet for Windows

## Requirements and Setup

The following are the system requirements to build CakeWallet for your Windows PC.

```txt
Windows 10 or later (64-bit), x86-64 based
Flutter 3.24.4
```

### 1. Installing Flutter

Install Flutter, specifically version `3.24.4` by following the [official docs](https://docs.flutter.dev/get-started/install/windows).

NOTE: as `3.24.4` is not the latest version, you'll need to download it from <https://docs.flutter.dev/release/archive> instead of the link in the docs above.

### 2. Install Development Tools

Install Git for Windows and Visual Studio 2022. Follow the [Development Tools](https://docs.flutter.dev/get-started/install/windows/desktop#development-tools) installation instructions.

Then install `Desktop development with C++` packages via Visual Studio 2022, or Visual Studio Build Tools 2022 including:

- `C++ Build Tools core features`
- `C++ 2022 Redistributable Update`
- `C++ core desktop features`
- `MVC v143 - VS 2022 C++ x64/x86 build tools`
- `C++ CMake tools for Windows`
- `Testing tools core features - Build Tools`
- `C++ AddressSanitizer`

### 3. Installing rustup

Install rustup from the [rustup.rs](https://rustup.rs/#) website, downloading and running the 64-bit `rustup-init.exe`.

### 4. Installing WSL (Windows Subsystem for Linux)

For building Monero dependencies, it is required to install Windows WSL (https://learn.microsoft.com/en-us/windows/wsl/install) and required packages for WSL (Ubuntu):

```zsh
sudo apt update 
sudo apt build-essential cmake gcc-mingw-w64 g++-mingw-w64 autoconf libtool pkg-config
```

### 5. Acquiring the Cake Wallet source code

Download the latest release tag of Cake Wallet and enter the source code directory:

```zsh
git clone https://github.com/cake-tech/cake_wallet.git --branch v4.23.0
cd cake_wallet
```

NOTE: Replace `v4.23.0` with the latest release tag available at <https://github.com/cake-tech/cake_wallet/releases/latest>.

### 6. Build Monero, monero_c, and dependencies

To use Monero in Cake Wallet, you must build the Monero_C wrapper which will be used by monero.dart package.

Run the following in a WSL terminal window:

```zsh
cd scripts/windows
./build_all.sh
```

### 7. Configure and build Cake Wallet application

To configure the application, run the following:

```zsh
./cakewallet.sh
```

After running the script above, you should to get `Cake Wallet.zip` in the project's root directory which will contain `CakeWallet.exe` and other needed files for running the application. Now you can extract files from `Cake Wallet.zip` archive and run the application.
