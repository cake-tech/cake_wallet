.PHONY: build-ios
build-ios:
	cargo build --target=aarch64-apple-ios

.PHONY: build-android
build-android:
	# cargo build --target=aarch64-linux-android
	cargo build --target=armv7-linux-androideabi

.PHONY: build
build: build-android copy
	echo "...done building :)"

.PHONY: copy
copy:
	cp target/aarch64-apple-ios/debug/libldk_ffi.a ios
	cp target/aarch64-linux-android/debug/libldk_ffi.so android/src/main/jniLibs/arm64-v8a
	cp target/armv7-linux-androideabi/debug/libldk_ffi.so android/src/main/jniLibs/armeabi-v7a