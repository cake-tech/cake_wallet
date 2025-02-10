# Building Cake Wallet for Linux

## Requirements and Setup

The following are the system requirements to build CakeWallet for your Linux device.

```txt
Ubuntu >= 16.04
Flutter 3.24.4
```

## Building CakeWallet on Linux

These steps will help you configure and execute a build of Cake Wallet from its source code.

### 1. Installing Package Dependencies

CakeWallet requires some packages to be installed on your build system. You may easily install them on your build system with the following command:

```bash
sudo apt install build-essential cmake pkg-config git curl autoconf libtool
```

### 2. Installing Flutter

Install Flutter, specifically version `3.24.4` by following the [official docs](https://docs.flutter.dev/get-started/install/linux).

NOTE: as `3.24.4` is not the latest version, you'll need to download it from <https://docs.flutter.dev/release/archive> instead of the link in the docs above.

### 3. Verify Installations

Verify that Flutter has been correctly installed on your system with the following command:

`flutter doctor`

The output of this command will appear like this, indicating successful installations. If there are problems with your installation, they **must** be corrected before proceeding.

```bash
Doctor summary (to see all details, run flutter doctor -v):
[✓] Flutter (Channel stable, 3.24.4, on Linux, locale en_US.UTF-8)
```

### 4. Acquiring the Cake Wallet source code

Download the latest release tag of Cake Wallet and enter the source code directory:

```zsh
git clone https://github.com/cake-tech/cake_wallet.git --branch v4.23.0
cd cake_wallet/scripts/linux/
```

NOTE: Replace `v4.23.0` with the latest release tag available at <https://github.com/cake-tech/cake_wallet/releases/latest>.

### 5. Setup and build Cake Wallet from source

We need to generate project settings like app name, app icon, package name, etc, including what specific variant of the app we want to build.

To configure the project, build Cake Wallet from source, and copy the necessary libraries over, run the following:

```zsh
./cakewallet.sh
./build_all.sh
./setup.sh
```

NOTE: This step will take quite a while, so be sure you grab a cup of coffee or a good book!

### 6. Prepare Flutter

Change back to the root directory of the Cake Wallet source code and install Flutter package dependencies:

```zsh
cd ../../
flutter pub get
```

Your Cake Wallet binary will be built with some specific keys for use with 3rd party services. You may generate these secret key placeholders with the following command, along with mobx models and localization files:

```bash
dart run tool/generate_new_secrets.dart`
./model_generator.sh`
dart run tool/generate_localization.dart
```

### 7. Build final binaries

```zsh
flutter build linux --release
```

The newly built executable file can be found at:

`build/linux/x64/release/bundle/cake_wallet`

### Troubleshooting

<!-- Is any of this still relevant? -->
> If you got an error while building the application with `$ flutter build linux --release` command, add `-v` argument to the command (`$ flutter build linux -v --release`) to get details.\
> If you got in flutter build logs: undefined reference to `hid_free_enumeration`, or another error with undefined reference to `hid_*`, then rebuild monero lib without hidapi lib. Check does exists `libhidapi-dev` in your scope and remove it from your scope for build without it.

> #### Check gcc version
>
> It is needed to use gcc 10 or 9 to successfully link dependencies with flutter.\
> To check what gcc version you are using:
>
> ```bash
> $ gcc --version
> $ g++ --version
> ```
>
> If you are using gcc version newer than 10, then you need to downgrade to version 10.4.0:
>
> ```bash
> $ sudo apt install gcc-10 g++-10
> $ sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-10 10
> $ sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-10 10
> ```

> [!NOTE]
>
> Alternatively, you can use the [nix-shell](https://nixos.org/) with the `gcc10.nix` file\
> present on `scripts/linux` like so:
> ```bash
> $ nix-shell gcc10.nix
> ```
> This will get you in a nix environment with all the required dependencies that you can use to build the software from,\
> and it works in any linux distro.

> #### If you will get an error like:
>
> ```
> The plugin `cw_shared_external` requires your app to be migrated to the Android embedding v2. Follow the steps on the migration doc above and re-run
> this command.
> ```
>
> Then need to config Android project settings. For this open `scripts/android` (`$ cd scripts/android`) directory and run followed commands:
>
> ```
> $ source ./app_env.sh cakewallet
> $ ./app_config.sh
> $ cd ../..
> ```
>
> Then re-configure Linux project again. For this open `scripts/linux` (`$cd scripts/linux`) directory and run:
> `$ ./cakewallet.sh`
> and back to project root directory:
> `$ cd ../..`
> and fetch dependencies again
> `$ flutter pub get`

## Flatpak (optional)

To package the built binaries as a flatpak, you need first to install `flatpak` and `flatpak-builder`:

```bash
sudo apt install flatpak flatpak-builder
```

Add the necessary Flathub:

```bash
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
```

Then need to install freedesktop runtime and sdk:

```bash
flatpak install flathub org.freedesktop.Platform//22.08 org.freedesktop.Sdk//22.08
```

Next, build the flatpak bundle:

```bash
flatpak-builder --force-clean flatpak-build com.cakewallet.CakeWallet.yml
```

And then export bundle:

```bash
flatpak build-export export flatpak-build
flatpak build-bundle export cake_wallet.flatpak com.cakewallet.CakeWallet
```

The Flatpak file, `cake_wallet.flatpak`, should be generated in the current directory.

To install the newly built Flatpak, run:

```bash
flatpak --user install cake_wallet.flatpak
```
