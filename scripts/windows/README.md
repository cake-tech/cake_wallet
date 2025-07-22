# Windows Build Instructions

## Prerequisites

Before building the Windows installer, make sure you have the following prerequisites:

1. Inno Setup installed on your system
2. Microsoft Visual C++ Redistributable for Visual Studio 2022 (x64) installer

## Downloading the VC++ Redistributable Installer

The Windows installer requires the Microsoft Visual C++ Redistributable for Visual Studio 2022 (x64) installer. You need to download it from Microsoft's website and place it in the same directory as the Inno Setup script (`build_exe_installer.iss`).

1. Download the VC++ Redistributable installer from: https://aka.ms/vs/17/release/vc_redist.x64.exe
2. Save the file as `vc_redist.x64.exe` in the `scripts\windows` directory

## Building the Installer

Once you have downloaded the VC++ Redistributable installer, you can build the Windows installer by running the Inno Setup script.

The installer will include the VC++ Redistributable and install it during the Cake Wallet installation process.
