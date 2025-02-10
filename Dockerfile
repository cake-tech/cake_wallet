# Set Flutter SDK version
ARG FLUTTER_VERSION=3.24.4

# Pull appropriate Flutter and Android SDK version
FROM instrumentisto/flutter:${FLUTTER_VERSION}

# Workaround tzdata and other packages needing interaction when installing/updating
ARG DEBIAN_FRONTEND=noninteractive

# Set Cake Wallet-specific variables
ARG CAKEWALLET_BRANCH=v4.23.0
ARG APP_NAME=cakewallet

# Set Android SDK environment variables
ENV ANDROID_HOME=/opt/android-sdk-linux \
    ANDROID_SDK_ROOT=$ANDROID_HOME \
    PATH=${PATH}:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools

SHELL ["/bin/bash", "-c"]

# Update all packages on the build host and install only necessary packages for building and clear cache
RUN apt-get update && apt-get install -y --no-install-recommends \
    autoconf \
    automake \
    build-essential \
    ca-certificates \
    clang \
    cmake \
    curl \
    file \
    gcc \
    g++ \
    gperf \
    git \
    lbzip2 \
    lcov \
    libgtk-3-dev \
    liblzma-dev \
    libtool \
    libtinfo6 \
    llvm-dev \
    make \
    ninja-build \
    openjdk-8-jre-headless \
    pkg-config \
    python-is-python3 \
    unzip \
    && apt clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
    
# Install Rust and cargo
RUN curl https://sh.rustup.rs -sSf | \
    sh -s -- --default-toolchain 1.84.1 -y && \
    . "$HOME/.cargo/env" && \
    cargo install cargo-ndk@3.5.4 --locked

# Get Cake Wallet source code
WORKDIR /opt/android
RUN git clone --branch ${CAKEWALLET_BRANCH} https://github.com/cake-tech/cake_wallet.git

# Install Android NDK
RUN . ./config.sh \
    TOOLCHAIN_DIR=${WORKDIR}/toolchain \
    TOOLCHAIN_A32_DIR=${TOOLCHAIN_DIR}_aarch \
    TOOLCHAIN_A64_DIR=${TOOLCHAIN_DIR}_aarch64 \
    TOOLCHAIN_x86_DIR=${TOOLCHAIN_DIR}_i686 \
    TOOLCHAIN_x86_64_DIR=${TOOLCHAIN_DIR}_x86_64 \
    ANDROID_NDK_SHA256="7a1302d9bfbc37d46be90b2285f4737508ffe08a346cf2424c5c6a744de2db22" \
    curl https://dl.google.com/android/repository/android-ndk-r27c-linux-x86_64.zip -o ${ANDROID_NDK_ZIP} && \
    echo $ANDROID_NDK_SHA256 $ANDROID_NDK_ZIP | sha256sum -c || exit 1 &&  \
    unzip $ANDROID_NDK_ZIP -d $WORKDIR &&  \
    ${ANDROID_NDK_ROOT}/build/tools/make_standalone_toolchain.py --arch arm64 --api $API --install-dir ${TOOLCHAIN_A64_DIR} --stl=libc++ \
    ${ANDROID_NDK_ROOT}/build/tools/make_standalone_toolchain.py --arch arm --api $API --install-dir ${TOOLCHAIN_A32_DIR} --stl=libc++ \
    ${ANDROID_NDK_ROOT}/build/tools/make_standalone_toolchain.py --arch x86 --api $API --install-dir ${TOOLCHAIN_x86_DIR} --stl=libc++ \
    ${ANDROID_NDK_ROOT}/build/tools/make_standalone_toolchain.py --arch x86_64 --api $API --install-dir ${TOOLCHAIN_x86_64_DIR} --stl=libc++

# Configure app details
RUN cd cake_wallet/scripts/android/ && \
    source ./app_env.sh ${APP_NAME} && \
    chmod +x pubspec_gen.sh && \
    ./app_config.sh

# Build Monero libraries
WORKDIR /opt/android/cake_wallet/scripts/android/
RUN set -x && source ./app_env.sh ${APP_NAME} && \
    ./build_monero_all.sh

# Build Haven libraries
RUN set -x && source ./app_env.sh ${APP_NAME} && \
    ./build_haven_all.sh

# Build mwebd libraries
RUN set -x && source ./app_env.sh ${APP_NAME} && \
    source ./config.sh && \
    ./build_mwebd.sh

# Fetch Flutter dependencies and setup salts + localization + model
RUN cd /opt/android/cake_wallet && \
    flutter pub get && \
    cd /opt/android/cake_wallet && \
    dart run tool/generate_localization.dart && \
    dart run tool/generate_new_secrets.dart && \
    ./model_generator.sh

# Build release APK file
RUN cd /opt/android/cake_wallet && \
    flutter build apk --release --split-per-abi

# Copy APK to build directory
RUN mkdir /build/ && \
    cp /opt/android/cake_wallet/build/app/outputs/flutter-apk/* /build/

VOLUME ["/build"]

CMD ["shasum", "-a 256", "/build/*.apk"]