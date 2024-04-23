# TODO(mrcyjanek): Cleanup, this is borrowed from unnamed_monero_wallet repo.

MONERO_C_TAG=v0.18.3.3-RC35
LIBCPP_SHARED_SO_TAG=latest-RC1
LIBCPP_SHARED_SO_NDKVERSION=r17c

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