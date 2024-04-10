# TODO(mrcyjanek): Cleanup, this is borrowed from unnamed_monero_wallet repo.

MONERO_C_TAG=v0.18.3.3-RC21
LIBCPP_SHARED_SO_TAG=latest-RC1
LIBCPP_SHARED_SO_NDKVERSION=r17c

.PHONY: android
android:
	./build_changelog.sh
	flutter build apk --split-per-abi --flavor calc  --dart-define=libstealth_calculator=true
	flutter build apk --split-per-abi --flavor clean --dart-define=libstealth_calculator=false

.PHONY: linux
linux: 
	./build_changelog.sh
	flutter build linux
	echo https://static.mrcyjanek.net/monero_c/${MONERO_C_TAG}/${TARGET_TRIPLET}_libwallet2_api_c.so.xz
	wget https://static.mrcyjanek.net/monero_c/${MONERO_C_TAG}/${TARGET_TRIPLET}_libwallet2_api_c.so.xz \
		-O build/linux/${FLUTTER_ARCH}/release/bundle/lib/libwallet2_api_c.so.xz
	-rm build/linux/${FLUTTER_ARCH}/release/bundle/lib/libwallet2_api_c.so
	unxz build/linux/${FLUTTER_ARCH}/release/bundle/lib/libwallet2_api_c.so.xz
	-rm build/linux/${FLUTTER_ARCH}/release/xmruw-linux-${DEBIAN_ARCH}.tar*
	(cd build/linux/${FLUTTER_ARCH}/release && cp -a bundle xmruw && tar -cvf xmruw-linux-${DEBIAN_ARCH}.tar xmruw && xz -e xmruw-linux-${DEBIAN_ARCH}.tar)


.PHONY: linux_debug_lib
linux_debug_lib:
	wget https://static.mrcyjanek.net/monero_c/${MONERO_C_TAG}/${shell gcc -dumpmachine}_libwallet2_api_c.so.xz \
		-O build/linux/${FLUTTER_ARCH}/debug/bundle/lib/libwallet2_api_c.so.xz
	-rm build/linux/${FLUTTER_ARCH}/debug/bundle/lib/libwallet2_api_c.so
	unxz build/linux/${FLUTTER_ARCH}/debug/bundle/lib/libwallet2_api_c.so.xz

deb:
	dart pub global activate --source git https://github.com/tomekit/flutter_to_debian.git
	cat debian/debian.yaml.txt | sed 's/x64/${FLUTTER_ARCH}/g' | sed 's/amd64/${DEBIAN_ARCH}/g' > debian/debian.yaml
	${HOME}/.pub-cache/bin/flutter_to_debian

.PHONY: dev
dev: libs

dev:
lib/const/resource.g.dart:
	dart pub global activate flutter_asset_generator
	timeout 15 ${HOME}/.pub-cache/bin/fgen || true
	mv lib/const/resource.dart lib/const/resource.g.dart
.PHONY: lib/const/resource.g.dart

.PHONY: sailfishos
sailfishos:
	./build_changelog.sh
	bash ./elinux/sailfish_build.sh

.PHONY: version
version:
	sed -i "s/^version: .*/version: 1.0.0+$(shell git rev-list --count HEAD)/" "pubspec.yaml"
	sed -i "s/^  Version: .*/  Version: 1.0.0+$(shell git rev-list --count HEAD)/" "debian/debian.yaml.txt"
	sed -i "s/^Version=.*/Version=1.0.0+$(shell git rev-list --count HEAD)/" "debian/gui/xmruw.desktop"
	sed -i "s/^Version=.*/Version=1.0.0+$(shell git rev-list --count HEAD)/" "elinux/unnamed-monero-wallet.desktop"
	sed -i "s/^Version:    .*/Version:    1.0.0+$(shell git rev-list --count HEAD)/" "elinux/sailfishos.spec"
	sed -i "s/^Release:    .*/Release:    $(shell git rev-list --count HEAD)/" "elinux/sailfishos.spec"
	sed -i "s/^Version:    .*/Version:    1.0.0+$(shell git rev-list --count HEAD)/" "elinux/sailfishos.spec"
	sed -i "s/^const xmruwVersion = .*/const xmruwVersion = '$(shell git describe --tags)';/" "lib/helpers/licenses_extra.dart"

.PHONY: lib/helpers/licenses.g.dart
lib/helpers/licenses.g.dart:
	dart pub run flutter_oss_licenses:generate.dart -o lib/helpers/licenses.g.dart

libs: android/app/src/main/jniLibs/arm64-v8a/libmonero_libwallet2_api_c.so
.PHONY: android/app/src/main/jniLibs/arm64-v8a/libmonero_libwallet2_api_c.so
android/app/src/main/jniLibs/arm64-v8a/libmonero_libwallet2_api_c.so:
	wget -q https://static.mrcyjanek.net/monero_c/${MONERO_C_TAG}/monero/aarch64-linux-android_libwallet2_api_c.so.xz -O android/app/src/main/jniLibs/arm64-v8a/libmonero_libwallet2_api_c.so.xz
	unxz android/app/src/main/jniLibs/arm64-v8a/libmonero_libwallet2_api_c.so.xz

libs: android/app/src/main/jniLibs/arm64-v8a/libc++_shared.so
.PHONY: android/app/src/main/jniLibs/arm64-v8a/libc++_shared.so
android/app/src/main/jniLibs/arm64-v8a/libc++_shared.so:
	wget -q https://git.mrcyjanek.net/mrcyjanek/libcpp_shared.so/releases/download/${LIBCPP_SHARED_SO_TAG}/${LIBCPP_SHARED_SO_NDKVERSION}_arm64-v8a_libc++_shared.so -O android/app/src/main/jniLibs/arm64-v8a/libc++_shared.so

libs: android/app/src/main/jniLibs/armeabi-v7a/libmonero_libwallet2_api_c.so
.PHONY: android/app/src/main/jniLibs/armeabi-v7a/libmonero_libwallet2_api_c.so
android/app/src/main/jniLibs/armeabi-v7a/libmonero_libwallet2_api_c.so:
	wget -q https://static.mrcyjanek.net/monero_c/${MONERO_C_TAG}/monero/arm-linux-androideabi_libwallet2_api_c.so.xz -O android/app/src/main/jniLibs/armeabi-v7a/libmonero_libwallet2_api_c.so.xz
	unxz android/app/src/main/jniLibs/armeabi-v7a/libmonero_libwallet2_api_c.so.xz

libs: android/app/src/main/jniLibs/armeabi-v7a/libc++_shared.so
.PHONY: android/app/src/main/jniLibs/armeabi-v7a/libc++_shared.so
android/app/src/main/jniLibs/armeabi-v7a/libc++_shared.so:
	wget -q https://git.mrcyjanek.net/mrcyjanek/libcpp_shared.so/releases/download/${LIBCPP_SHARED_SO_TAG}/${LIBCPP_SHARED_SO_NDKVERSION}_armeabi-v7a_libc++_shared.so -O android/app/src/main/jniLibs/armeabi-v7a/libc++_shared.so

# libs: android/app/src/main/jniLibs/x86/libmonero_libwallet2_api_c.so
# .PHONY: android/app/src/main/jniLibs/x86/libmonero_libwallet2_api_c.so
# android/app/src/main/jniLibs/x86/libmonero_libwallet2_api_c.so:
# 	wget -q https://static.mrcyjanek.net/monero_c/${MONERO_C_TAG}/monero/i686-linux-android_libwallet2_api_c.so.xz -O android/app/src/main/jniLibs/x86/libmonero_libwallet2_api_c.so.xz
# 	unxz android/app/src/main/jniLibs/x86/libmonero_libwallet2_api_c.so.xz

libs: android/app/src/main/jniLibs/x86/libc++_shared.so
.PHONY: android/app/src/main/jniLibs/x86/libc++_shared.so
android/app/src/main/jniLibs/x86/libc++_shared.so:
	wget -q https://git.mrcyjanek.net/mrcyjanek/libcpp_shared.so/releases/download/${LIBCPP_SHARED_SO_TAG}/${LIBCPP_SHARED_SO_NDKVERSION}_x86_libc++_shared.so -O android/app/src/main/jniLibs/x86/libc++_shared.so

libs: android/app/src/main/jniLibs/x86_64/libmonero_libwallet2_api_c.so
.PHONY: android/app/src/main/jniLibs/x86_64/libmonero_libwallet2_api_c.so
android/app/src/main/jniLibs/x86_64/libmonero_libwallet2_api_c.so:
	wget -q https://static.mrcyjanek.net/monero_c/${MONERO_C_TAG}/monero/x86_64-linux-android_libwallet2_api_c.so.xz -O android/app/src/main/jniLibs/x86_64/libmonero_libwallet2_api_c.so.xz
	unxz android/app/src/main/jniLibs/x86_64/libmonero_libwallet2_api_c.so.xz

libs: android/app/src/main/jniLibs/x86_64/libc++_shared.so
.PHONY: android/app/src/main/jniLibs/x86_64/libc++_shared.so
android/app/src/main/jniLibs/x86_64/libc++_shared.so:
	wget -q https://git.mrcyjanek.net/mrcyjanek/libcpp_shared.so/releases/download/${LIBCPP_SHARED_SO_TAG}/${LIBCPP_SHARED_SO_NDKVERSION}_x86_64_libc++_shared.so -O android/app/src/main/jniLibs/x86_64/libc++_shared.so

clean_libs:
	-rm android/app/src/main/jniLibs/x86_64/libc++_shared.so*
	-rm android/app/src/main/jniLibs/x86_64/*_libwallet2_api_c.so*
	-rm android/app/src/main/jniLibs/armeabi-v7a/libc++_shared.so*
	-rm android/app/src/main/jniLibs/armeabi-v7a/*_libwallet2_api_c.so*
	-rm android/app/src/main/jniLibs/x86/libc++_shared.so*
	-rm android/app/src/main/jniLibs/x86/*_libwallet2_api_c.so*
	-rm android/app/src/main/jniLibs/arm64-v8a/libc++_shared.so*
	-rm android/app/src/main/jniLibs/arm64-v8a/*_libwallet2_api_c.so*