# Building CakeWallet for Windows

## Requirements and Setup

The following are the system requirements to build CakeWallet for your Windows PC.

```
Windows 10 or later (64-bit), x86-64 based
Flutter 3 or above
```

## Building CakeWallet on Windows

These steps will help you configure and execute a build of CakeWallet from its source code.

### 1. Installing Package Dependencies

For build CakeWallet windows application from sources you will be needed to have:
> [Install Flutter](https://docs.flutter.dev/get-started/install/windows) follow this guide until `Android setup` section (it's not necessary for this build process).
> [Install adition for Flutter SDK](https://docs.flutter.dev/platform-integration/desktop#additional-windows-requirements). Then install `Desktop development with C++` packages via GUI Visual Studio 2022, or Visual Studio Build Tools 2022 including: `C++ Build Tools core features`, `C++ 2022 Redistributable Update`, `C++ core desktop features`, `MVC v143 - VS 2022 C++ x64/x86 build tools`, `C++ CMake tools for Windwos`, `Testing tools core features - Build Tools`, `C++ AddressSanitizer`.

### 2. Pull CakeWallet source code

You can downlaod CakeWallet source code from our [GitHub repository](github.com/cake-tech/cake_wallet) via git by following next command:
`$ git clone https://github.com/cake-tech/cake_wallet.git --branch windows`
OR you can download it as [Zip archive](https://github.com/cake-tech/cake_wallet/archive/refs/heads/windows.zip)

### 3. Configure and build CakeWallet application
To configure the application open directory where you have downloaded or unarchived CakeWallet sources and run `cakewallet.bat`.
After execution of `cakewallet.bat` you should to get `Cake Wallet.zip` in project root directory which will contains `CakeWallet.exe` file and another needed files for run the application. Now you can extract files from `Cake Wallet.zip` archive and run the application.
