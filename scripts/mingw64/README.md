# `flutter_libmonero`
## Building on Windows with MSYS2 MinGW64

- [x] `iconv`
- [x] `boost`
See https://gist.github.com/zrsmithson/0b72e0cb58d0cb946fc48b5c88511da8
- [x] `zlib`
See https://gist.github.com/baoilleach/5975580
- [x] `openssl`
See https://wiki.qt.io/Compiling_OpenSSL_with_MinGW
- [x] `sodium`
- [x] `expat`
- [ ] `unbound`
- [ ] `zmq`
- [ ] `monero`

### Prerequisites
 - [MSYS2](https://www.msys2.org/)

### MSYS2 Dependencies
In a MSYS2 MinGW64 shell:
```shell
pacman -S base-devel gcc cmake libtool autoconf automake libtool
```
<!-- Do we need to also install mingw-w64-x86_64-cmake ? -->

### Build
Run `build_all.sh`

Libraries will be output to `scripts/winwin/build`

See https://fossies.org/linux/unbound/winrc/README.txt "+++ Cross compile"

See http://wiki.zeromq.org/build:mingw

See https://github.com/monero-project/monero/blob/master/README.md#on-windows

## Building on Windows with MSVC

- [x] `iconv`
- [x] `boost`
- [x] `zlib`
- [x] `openssl`
- [x] `sodium`
- [ ] `expat`
- [ ] `unbound`
- [ ] `zmq`
- [ ] `monero`

### Prerequisites
 - Visual Studio Code 2019
 	Also install C/C++ build tools, the Windows 10 SDK, and the .NET 6.0 SDK
 - Boost 1.80.0 source code
 	Download boost from https://www.boost.org/users/download/
 - Perl
	https://strawberryperl.com/

### `cypherstack/flutter-libmonero`
Clone `cypherstack/flutter-libmonero`
```shell
	git clone https://github.com/cypherstack/flutter-libmonero
```

We will place all statically-built libraries in `flutter_libmonero\scripts\windows\build\prefix_x86_64`

### `libiconv`
Clone `kiyolee/libiconv-win-build`
```shell
	git clone https://github.com/kiyolee/libiconv-win-build
```

Open up the relevant solution file (`libiconv-win-build\build-VS2019\libiconv.sln`) and build a x64 image for release.  Copy the statically-generated library file `build-VS2019\x64\Release\libiconv-static.lib` to `flutter_libmonero\scripts\windows\build\prefix_x86_64` and rename it to `libiconv.lib`
```shell
	Copy-Item "libiconv-win-build\build-VS2019\x64\Release\libiconv-static.lib" -Destination "\flutter_libmonero\scripts\windows\build\prefix_x86_64\libiconv.lib"
```

### `boost`
See `build_boost.sh` for downloading Boost

```shell
.\bootstrap.bat --prefix="C:\AndroidStudioproj\firo_wallet\crypto_plugins\flutter_libmonero\scripts\windows\build\prefix_x86_64"

.\b2.exe release debug --toolset=msvc address-model=64 --build-type=minimal link=static runtime-link=static --with-chrono --with-date_time --with-filesystem --with-program_options --with-regex --with-serialization --with-system --with-thread --with-locale threading=multi target-os=windows -sICONV_PATH="C:\AndroidStudioproj\firo_wallet\crypto_plugins\flutter_libmonero\scripts\windows\build\prefix_x86_64" stage
```

### `zlib`
```shell
git clone -b v1.2.12 --depth 1 https://github.com/madler/zlib
nmake -f .\win32\Makefile.msc
```

### `openssl`
See `build_openssl.sh` for downloading OpenSSL

```shell
perl Configure --no-shared --with-zlib-include="C:\AndroidStudioproj\firo_wallet\crypto_plugins\flutter_libmonero\scripts\windows\build\prefix_x86_64\include" --with-zlib-lib="C:\AndroidStudioproj\firo_wallet\crypto_plugins\flutter_libmonero\scripts\windows\build\prefix_x86_64\lib" VC-WIN32

nmake
```

### `sodium`
See `build_sodium.sh` for downloading Sodium

Build `libsodium.sln` for release
```shell
msbuild .\libsodium.sln /p:PlatformTarget=x86_64 /property:Configuration=Release -m /p:OutputPath="C:\AndroidStudioproj\firo_wallet\crypto_plugins\flutter_libmonero\scripts\windows\build\libsodium\output"
```

### `expat`
See `build_expat.sh` for downloading Expat

```shell
cmake -G"Visual Studio 15 2017" -DCMAKE_BUILD_TYPE=RelWithDebInfo ..
msbuild /m expat.sln
```

### `unbound`
TODO

### `zmq`
TODO

### `monero`
TODO

## Building for Windows on Ubuntu 20.04
Cross-compilation for Windows from Ubuntu/linux is broken, stuck on an issue with unbound where it doesn't properly detect OpenSSL or OpenSSL isn't compiled correctly.  Please submit an issue or a pull request if you can contribute a fix!

### Install dependencies
Run `monerodeps.sh` to install Monero dependencies, or use the command below:
```bash
sudo apt install libsecret-1-dev libjsoncpp-dev libsecret-1-0
```

Run `mxedeps.sh` to install MXE and its dependencies, or use the commands below:
```bash
sudo apt-get install p7zip-full autoconf automake autopoint bash bison bzip2 cmake flex gettext git g++ gperf intltool libffi-dev libtool libtool-bin libltdl-dev libssl-dev libxml-parser-perl make openssl patch perl pkg-config python ruby scons sed unzip wget xz-utils g++-multilib libc6-dev-i386 lzip

# Install MXE to ~/development/mxe
mkdir -p ~/development
cd ~/development
git clone https://github.com/mxe/mxe.git
cd mxe
make cc cmake MXE_TARGETS='x86_64-w64-mingw32.static'
if ! [[ $PATH == *"/mxe"* ]]; then
  echo 'export PATH="$HOME/development/mxe/usr/bin:$PATH"' >> ~/.bashrc  # Prepend to PATH
  source ~/.bashrc
fi
make cmake openssl MXE_TARGETS='x86_64-w64-mingw32.static'
```

### Build
Run `build_all.sh` (may need to alter permissions like `chmod +x *.sh`)

Libraries will be output to `scripts/windows/build`

## Notes
See https://www.oodlestechnologies.com/blogs/how-to-compile-altcoin-for-windows-on-linux-using-mxe-and-mingw/
