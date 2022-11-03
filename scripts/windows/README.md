# `flutter_libmonero`
## Building for Windows
### Install dependencies
Run `monerodeps.sh` to install Monero dependencies, or use the commands below:
```bash
sudo apt install libsecret-1-dev libjsoncpp-dev libsecret-1-0
```

## Build
Run `build_all.sh` (may need to alter permissions like `chmod +x *.sh`)

Libraries will be output to `scripts/windows/build`

## Building on Windows
Windows builds are broken, but the following notes may assist in setup:

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
```shell
perl Configure --no-shared --with-zlib-include="C:\AndroidStudioproj\firo_wallet\crypto_plugins\flutter_libmonero\scripts\windows\build\prefix_x86_64\include" --with-zlib-lib="C:\AndroidStudioproj\firo_wallet\crypto_plugins\flutter_libmonero\scripts\windows\build\prefix_x86_64\lib" VC-WIN32

nmake
```

### `libsodium`
open up visual studio solutions file and build the release version
```shell
msbuild .\libsodium.sln /p:PlatformTarget=x86 /property:Configuration=Release -m /p:OutputPath="C:\AndroidStudioproj\firo_wallet\crypto_plugins\flutter_libmonero\scripts\windows\build\libsodium\output"
```

### `libexpat`
```shell
cmake -G"Visual Studio 15 2017" -DCMAKE_BUILD_TYPE=RelWithDebInfo ..
msbuild /m expat.sln
```