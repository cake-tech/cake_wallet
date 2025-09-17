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

if [[ "x$ANDROID_NDK_VERSION" == "x" ]];
then
    echo "ANDROID_NDK_VERSION is missing, please declare it before building"
    echo "You have these versions installed on your system currently:"
    ls ${ANDROID_HOME}/ndk/ | cat | awk '{ print "- " $1 }'
    echo "echo > ~/.zprofile"
    echo "echo 'export ANDROID_NDK_VERSION=..... > ~/.zprofile"
    exit 1
fi

export ANDROID_OUT=../android/src/main/jniLibs
export ANDROID_SDK="${HOME}/Library/Android/sdk"
export NDK_BIN="${ANDROID_HOME}/ndk/${ANDROID_NDK_VERSION}/toolchains/llvm/prebuilt/$(uname | tr '[:upper:]' '[:lower:]')-x86_64/bin"

# Compile for x86_64 architecture and place the binary file in the android/src/main/jniLibs/x86_64 folder
export CGO_LDFLAGS="-O2 -g -s -w -Wl,-z,max-page-size=16384"

CGO_ENABLED=1 \
GOOS=android \
GOARCH=amd64 \
CC=${NDK_BIN}/x86_64-linux-android21-clang \
go build -v -buildmode=c-shared -o ${ANDROID_OUT}/x86_64/libmweb.so .

# Compile for arm64 architecture and place the binary file in the android/src/main/jniLibs/arm64-v8a folder
CGO_ENABLED=1 \
GOOS=android \
GOARCH=arm64 \
CC=${NDK_BIN}/aarch64-linux-android21-clang \
go build -v -buildmode=c-shared -o ${ANDROID_OUT}/arm64-v8a/libmweb.so .

# Compile for armv7a architecture and place the binary file in the android/src/main/jniLibs/armeabi-v7a folder
CGO_ENABLED=1 \
GOOS=android \
GOARCH=arm \
CC=${NDK_BIN}/armv7a-linux-androideabi21-clang \
go build -v -buildmode=c-shared -o ${ANDROID_OUT}/armeabi-v7a/libmweb.so .
cd ../
dart run ffigen --config ffigen_config.yaml
