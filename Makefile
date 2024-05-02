LIBCPP_SHARED_SO_TAG=latest-RC1
LIBCPP_SHARED_SO_NDKVERSION=r17c

libs: android/app/src/main/jniLibs/arm64-v8a/libc++_shared.so
.PHONY: android/app/src/main/jniLibs/arm64-v8a/libc++_shared.so
android/app/src/main/jniLibs/arm64-v8a/libc++_shared.so:
	wget -q https://git.mrcyjanek.net/mrcyjanek/libcpp_shared.so/releases/download/${LIBCPP_SHARED_SO_TAG}/${LIBCPP_SHARED_SO_NDKVERSION}_arm64-v8a_libc++_shared.so -O android/app/src/main/jniLibs/arm64-v8a/libc++_shared.so

libs: android/app/src/main/jniLibs/armeabi-v7a/libc++_shared.so
.PHONY: android/app/src/main/jniLibs/armeabi-v7a/libc++_shared.so
android/app/src/main/jniLibs/armeabi-v7a/libc++_shared.so:
	wget -q https://git.mrcyjanek.net/mrcyjanek/libcpp_shared.so/releases/download/${LIBCPP_SHARED_SO_TAG}/${LIBCPP_SHARED_SO_NDKVERSION}_armeabi-v7a_libc++_shared.so -O android/app/src/main/jniLibs/armeabi-v7a/libc++_shared.so

libs: android/app/src/main/jniLibs/x86/libc++_shared.so
.PHONY: android/app/src/main/jniLibs/x86/libc++_shared.so
android/app/src/main/jniLibs/x86/libc++_shared.so:
	wget -q https://git.mrcyjanek.net/mrcyjanek/libcpp_shared.so/releases/download/${LIBCPP_SHARED_SO_TAG}/${LIBCPP_SHARED_SO_NDKVERSION}_x86_libc++_shared.so -O android/app/src/main/jniLibs/x86/libc++_shared.so

libs: android/app/src/main/jniLibs/x86_64/libc++_shared.so
.PHONY: android/app/src/main/jniLibs/x86_64/libc++_shared.so
android/app/src/main/jniLibs/x86_64/libc++_shared.so:
	wget -q https://git.mrcyjanek.net/mrcyjanek/libcpp_shared.so/releases/download/${LIBCPP_SHARED_SO_TAG}/${LIBCPP_SHARED_SO_NDKVERSION}_x86_64_libc++_shared.so -O android/app/src/main/jniLibs/x86_64/libc++_shared.so

clean_libs:
	-rm android/app/src/main/jniLibs/x86_64/libc++_shared.so*
	-rm android/app/src/main/jniLibs/armeabi-v7a/libc++_shared.so*
	-rm android/app/src/main/jniLibs/x86/libc++_shared.so*
	-rm android/app/src/main/jniLibs/arm64-v8a/libc++_shared.so*