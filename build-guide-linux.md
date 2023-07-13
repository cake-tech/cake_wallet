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

> ### Check gcc version
> Need to use gcc 10 or 9 for successfully link dependecnies with flutter.\
> Check what gcc version is using:\
> ```
> $ gcc --version
> $ g++ --version
> ```
> If you are using gcc version newer than 10, then need to downgrade to version 10.4.0.\
> ```
> $ sudo apt install gcc-10 g++-10
> $ sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-10 10
> $ sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-10 10
> ```

### 2. Installing Flutter

Need to install flutter. For this please check section [How to install flutter on Linux](https://docs.flutter.dev/get-started/install/linux).




### 3. Verify Installations

Verify that the Flutter have been correctly installed on your system with the following command:

`$ flutter doctor`

The output of this command will appear like this, indicating successful installations. If there are problems with your installation, they **must** be corrected before proceeding.
```
Doctor summary (to see all details, run flutter doctor -v):
[✓] Flutter (Channel stable, 3.7.x, on Linux, locale en_US.UTF-8)
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


> ### If you get the error like:
> ```
> The lower bound of "sdk: '>=2.0.0-dev.68.0 <3.0.0'" must be 2.12.0 or higher to enable null safety.
> ```
>
> #### Downgrade Flutter to version 3.7.x
> Make sure that Flutter is reverted back to version 3.7.x (which would automatically revert Dart to 2.18 or 2.19)
> 
> In your Linux terminal, find where your Flutter SDK is installed with:
> 
> ```
> $ which flutter
> ```
> 
> Proceed to the Flutter SDK path:
> 
> ```
> $ cd user/snap/flutter/common/flutter
> ```
> 
> In the Flutter SDK directory, revert to a 3.7.x version (I used 3.7.12):
> 
> 
> ```
> $ git checkout 3.7.12
> ```
> Then re-configure Cake Wallet's Linux project again. For this open `scripts/linux` (`$cd scripts/linux`) directory and run:
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

> ### Troubleshooting
>
> If you got an error while building the application with `$ flutter build linux --release` command, add `-v` argument to the command (`$ flutter build linux -v --release`) to get details.\
> If you got in flutter build logs: undefined reference to `hid_free_enumeration`, or another error with undefined reference to `hid_*`, then rebuild monero lib without hidapi lib. Check does exists `libhidapi-dev` in your scope and remove it from your scope for build without it.

# Flatpak

For package the built application into flatpak you need fistly to install `flatpak` and `flatpak-builder`:

`$ sudo apt install flatpak flatpak-builder`

Then need to [add flathub](https://flatpak.org/setup/Ubuntu) (or just `$ flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo`). Then need to install freedesktop runtime and sdk:

`$ flatpak install flathub org.freedesktop.Platform//22.08 org.freedesktop.Sdk//22.08`

To build with using of `flatpak-build` directory run next:

`$ flatpak-builder --force-clean flatpak-build com.cakewallet.CakeWallet.yml`

And then export bundle:

`$ flatpak build-export export flatpak-build`

`$ flatpak build-bundle export cake_wallet.flatpak com.cakewallet.CakeWallet`


Result file: `cake_wallet.flatpak` should be generated in current directory.

For install generated flatpak file use:

`$ flatpak --user install cake_wallet.flatpak`

For run the installed application run:

`$ flatpak run com.cakewallet.CakeWallet`

Copyright (c) 2023 Cake Technologies LLC.