# Building Cake Wallet for Windows

## Requirements and Setup

The following are the system requirements to build CakeWallet for your Windows PC.

```
Windows 10 or later (64-bit), x86-64 based
Flutter 3.24.4
```

### 1. Installing Flutter

Install Flutter with version `3.24.4`. Follow the Flutter [installation guide](https://docs.flutter.dev/get-started/install/windows).

### 2. Install Development Tools

Install Git for Windows and Visual Studio 2022. Follow the [Development Tools](https://docs.flutter.dev/get-started/install/windows/desktop#development-tools) installation instructions.

Then install `Desktop development with C++` packages via Visual Studio 2022, or Visual Studio Build Tools 2022 including:
- `C++ Build Tools core features`
- `C++ 2022 Redistributable Update`
- `C++ core desktop features`
- `MVC v143 - VS 2022 C++ x64/x86 build tools`
- `C++ CMake tools for Windows`
- `Testing tools core features - Build Tools`
- `C++ AddressSanitizer`.

### 3. Installing rustup

Install rustup from the [rustup.rs](https://rustup.rs/#) website. Download and run the 64-bit rustup-init.exe

### 4. Installing WSL (Windows Subsystem for Linux)

For building monero dependencies, it is required to install Windows WSL (https://learn.microsoft.com/en-us/windows/wsl/install) and required packages for WSL (Ubuntu):
`$ sudo apt update `
`$ sudo apt build-essential cmake gcc-mingw-w64 g++-mingw-w64 autoconf libtool pkg-config`

### 5. Pull Cake Wallet source code

You can download CakeWallet source code from our [GitHub repository](github.com/cake-tech/cake_wallet) via git:
`$ git clone https://github.com/cake-tech/cake_wallet.git --branch MrCyjaneK-cyjan-monerodart`
OR you can download it as [Zip archive](https://github.com/cake-tech/cake_wallet/archive/refs/heads/MrCyjaneK-cyjan-monerodart.zip)

### 6. Build Monero, monero_c and their dependencies

To use Monero in Cake Wallet, you must build the Monero_C wrapper which will be used by monero.dart package.

For that you need to run the shell (bash - typically same named utility should be available after WSL is enabled in your system) with the previously installed WSL install, then change current directory to the application project directory with your shell then change current directory to `scripts/windows`: `$ cd scripts/windows`. Run build script: `$ ./build_all.sh`.

### 7. Configure and build Cake Wallet application

To configure the application, open the directory where you have downloaded or unarchived Cake Wallet sources and run `cakewallet.bat`.
Or if you used WSL and have active shell session you can run `$ ./cakewallet.sh` script in `scripts/windows` which will run `cakewallet.bat` in WSL.
After execution of `cakewallet.bat` you should to get `Cake Wallet.zip` in project root directory which will contain `CakeWallet.exe` file and another needed files for run the application. Now you can extract files from `Cake Wallet.zip` archive and run the application.

Copyright (c) 2024 Cake Labs LLC.
