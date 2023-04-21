# Building CakeWallet for Linux

## Requirements and Setup

The following are the system requirements to build CakeWallet for your Linux device.

```
Ubuntu >= 16.04 
Flutter 3 or above
```

## Building CakeWallet on Linux

These steps will help you configure and execute a build of CakeWallet from its source code.

### 1. Installing Package Dependencies

CakeWallet requires some packages to be install on your build system. You may easily install them on your build system with the following command:

`$ sudo apt install build-essential cmake pkg-config git curl autoconf libtool`

### 2. Installing Flutter

Need to install flutter. For this please check section [How to install flutter on Linux](https://docs.flutter.dev/get-started/install/linux).

### 3. Verify Installations

Verify that the Flutter have been correctly installed on your system with the following command:

`$ flutter doctor`

The output of this command will appear like this, indicating successful installations. If there are problems with your installation, they **must** be corrected before proceeding.
```
Doctor summary (to see all details, run flutter doctor -v):
[✓] Flutter (Channel stable, 3.x.x, on Linux, locale en_US.UTF-8)
```

### 4. Acquiring the CakeWallet Source Code

Download CakeWallet source code

`$ git clone https://github.com/cake-tech/cake_wallet.git --branch linux/password-direct-input`

Proceed into the source code before proceeding with the next steps:

`$ cd cake_wallet/scripts/linux/`

To configure some project properties run:

`$ ./cakewallet.sh`

Build the Monero libraries and their dependencies:

`$ ./build_all.sh`

Now the dependencies need to be copied into the CakeWallet project with this command:

`$ ./setup.sh`

It is now time to change back to the base directory of the CakeWallet source code:

`$ cd ../../`

Install Flutter package dependencies with this command:

`$ flutter pub get`



> #### If you will get an error like:
> ```
> The plugin `cw_shared_external` requires your app to be migrated to the Android embedding v2. Follow the steps on the migration doc above and re-run
> this command.
> ```
> Then need to config Android project settings. For this open `scripts/android` (`$ cd scripts/android`) directory and run followed commands:
> ```
> $ source ./app_env.sh cakewallet
> $ ./app_config.sh
> $ cd ../..
> ```
> Then re-configure Linux project again. For this open `scripts/linux` (`$cd scripts/linux`) directory and run:
> `$ ./cakewallet.sh`
> and back to project root directory:
> `$ cd ../..`
> and fetch dependecies again
> `$ flutter pub get`



Your CakeWallet binary will be built with some specific keys for iterate with 3rd party services. You may generate these secret keys placeholders with the following command:

`$ flutter packages pub run tool/generate_new_secrets.dart`

We will generate mobx models for the project.

`$ ./model_generator.sh`

Then we need to generate localization files.

`$ flutter packages pub run tool/generate_localization.dart`

### 5. Build!

`$ flutter build linux --release`

Path to executable file will be:

`build/linux/x64/release/bundle/cake_wallet`

Copyright (c) 2023 Cake Technologies LLC.