# Building CakeWallet for Android

## Requirements and Setup

The following are the system requirements to build CakeWallet for your Android device.

```
Ubuntu >= 16.04 
Android SDK 28
Android NDK 17c
Flutter 2 or above
```

## Building CakeWallet on Android

These steps will help you configure and execute a build of CakeWallet from its source code.

### 1. Installing Package Dependencies

CakeWallet cannot be built without the following packages installed on your build system.

- unzip

- automake

- build-essential

- file

- pkg-config

- git

- python

- libtool

- libtinfo5

- cmake

- openjdk-8-jre-headless

You may easily install them on your build system with the following command:

`$ sudo apt-get install -y unzip automake build-essential file pkg-config git python libtool libtinfo5 cmake openjdk-8-jre-headless`

### 2. Installing Android Studio and Android toolchain

You may download and install the latest version of Android Studio [here](https://developer.android.com/studio#downloads). After installing, start Android Studio, and go through the "Setup Wizard." This installs the latest Android SDK, Android SDK Command-line Tools, and Android SDK Build-Tools, which are required by CakeWallet. **Be sure you are installing SDK version 28 or later when stepping through the wizard**

### 3. Installing Flutter

Need to install flutter. For this please check section [Install Flutter manually](https://docs.flutter.dev/get-started/install/linux#install-flutter-manually).

### 4. Verify Installations

Verify that the Android toolchain, Flutter, and Android Studio have been correctly installed on your system with the following command:

`$ flutter doctor`

The output of this command will appear like this, indicating successful installations. If there are problems with your installation, they **must** be corrected before proceeding.
```
Doctor summary (to see all details, run flutter doctor -v):
[✓] Flutter (Channel stable, 2.0.4, on Linux, locale en_US.UTF-8)
[✓] Android toolchain - develop for Android devices (Android SDK version 28)
[✓] Android Studio (version 4.0)
```

### 5. Generate a secure keystore for Android

`$ keytool -genkey -v -keystore $HOME/key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias key`

You will be prompted to create two passwords. First you will be prompted for the "store password", followed by a "key password" towards the end of the creation process. **TAKE NOTE OF THESE PASSWORDS!** You will need them in later steps. 

### 6. Acquiring the CakeWallet Source Code

Create the directory that will be use to store the CakeWallet source and download the source code into that directory.

`$ git clone https://github.com/cypherstack/flutter_libmonero.git --branch main`

Proceed into the source code before proceeding with the next steps:

`$ cd cake_wallet/scripts/android/`

### 7. Installing Android NDK

`$ ./install_ndk.sh`

### 8. Execute Build & Setup Commands for CakeWallet

Build the Monero libraries and their dependencies:

`$ ./build_monero_all.sh`

Now the dependencies need to be copied into the CakeWallet project with this command:

`$ ./copy_monero_deps.sh`

It is now time to change back to the base directory of the CakeWallet source code:

`$ cd ../../`

Install Flutter package dependencies with this command:

`$ flutter pub get`

Your CakeWallet binary will be built with cryptographic salts, which are used for secure encryption of your data. You may generate these secret salts with the following command:

`$ flutter packages pub run tool/generate_new_secrets.dart`

### 9. Build!

`$ flutter build apk --release`

Copyright (c) 2022 Cake Technologies LLC.
