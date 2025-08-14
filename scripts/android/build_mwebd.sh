if [[ "$1" == "--dont-install" ]]; then
  echo "Skipping Go installation as per --dont-install flag"
else
  # install go > 1.24:
  wget https://go.dev/dl/go1.24.1.linux-amd64.tar.gz
  sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.24.1.linux-amd64.tar.gz
  export PATH=$PATH:/usr/local/go/bin
  export PATH=$PATH:~/go/bin
fi

cd ../../cw_mweb/go

export ANDROID_OUT=../android/src/main/jniLibs
export ANDROID_SDK="${HOME}/Library/Android/sdk"
export NDK_BIN="${ANDROID_SDK}/ndk/28.2.13676358/toolchains/llvm/prebuilt/darwin-x86_64/bin"

# Compile for x86_64 architecture and place the binary file in the android/src/main/jniLibs/x86_64 folder
CGO_ENABLED=1 \
GOOS=android \
GOARCH=amd64 \
CC=${NDK_BIN}/x86_64-linux-android21-clang \
go build -buildmode=c-shared -o ${ANDROID_OUT}/x86_64/mweb.so .

# Compile for arm64 architecture and place the binary file in the android/src/main/jniLibs/arm64-v8a folder
CGO_ENABLED=1 \
GOOS=android \
GOARCH=arm64 \
CC=${NDK_BIN}/aarch64-linux-android21-clang \
go build -buildmode=c-shared -o ${ANDROID_OUT}/arm64-v8a/mweb.so .

cd ../dart run ffigen --config ffigen_config.yaml
