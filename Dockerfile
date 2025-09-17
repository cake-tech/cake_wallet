# docker buildx build --push --pull --platform linux/amd64,linux/arm64 . -f Dockerfile -t ghcr.io/cake-tech/cake_wallet:debian12-flutter3.32.0-ndkr28-go1.24.1-ruststablenightly

# Heavily inspired by cirrusci images
# https://github.com/cirruslabs/docker-images-android/blob/master/sdk/tools/Dockerfile
# https://github.com/cirruslabs/docker-images-android/blob/master/sdk/34/Dockerfile
# https://github.com/cirruslabs/docker-images-android/blob/master/sdk/34-ndk/Dockerfile
# https://github.com/cirruslabs/docker-images-flutter/blob/master/sdk/Dockerfile

FROM docker.io/debian:12

LABEL org.opencontainers.image.source=https://github.com/cake-tech/cake_wallet

# Set necessary environment variables
# Set Go version to latest known-working version
ENV GOLANG_VERSION=1.24.1

# Pin Flutter version to latest known-working version
ENV FLUTTER_VERSION=3.32.0

# Pin Android Studio, platform, and build tools versions to latest known-working version
# Comes from https://developer.android.com/studio/#command-tools
ENV ANDROID_SDK_TOOLS_VERSION=13114758
# Comes from https://developer.android.com/studio/releases/build-tools
ENV ANDROID_PLATFORM_VERSION=35
ENV ANDROID_BUILD_TOOLS_VERSION=34.0.0

# If we ever need to migrate the home directory...
RUN sed -i 's|^root:[^:]*:[^:]*:[^:]*:[^:]*:/root:|root:x:0:0:root:/root:|' /etc/passwd
# mkdir -p /root && rm -rf /root && cp -a /root /root
ENV HOME=/root
ENV ANDROID_HOME=/opt/android-sdk-linux \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    LANGUAGE=en_US:en

# Set Android SDK paths
ENV ANDROID_SDK_ROOT=$ANDROID_HOME \
    PATH=${PATH}:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/emulator

# Upgrade base image
RUN apt-get update \
    && apt-get upgrade -y

# Install all build dependencies
RUN set -o xtrace \
    && cd /opt \
    && apt-get install -y --no-install-recommends --no-install-suggests \
    # Core dependencies
    bc build-essential curl default-jdk git jq lcov libglu1-mesa libpulse0 libsqlite3-dev libstdc++6 locales openssh-client ruby-bundler ruby-full software-properties-common sudo unzip wget zip \
    # for x86 emulators
    libatk-bridge2.0-0 libgdk-pixbuf2.0-0 libgtk-3-0 libnspr4 libnss3-dev libsqlite3-dev libxtst6 libxss1 lftp sqlite3 xxd \
    # Linux desktop dependencies
    clang cmake libgtk-3-dev ninja-build pkg-config \
    # monero_c dependencies
    autoconf automake build-essential ccache gperf libtool llvm \
    # extra stuff for KVM
    bridge-utils libvirt-clients libvirt-daemon-system qemu-kvm udev \
    # Linux test dependencies
    ffmpeg network-manager x11-utils xvfb psmisc \
    # aarch64-linux-gnu dependencies
    g++-aarch64-linux-gnu gcc-aarch64-linux-gnu \
    # x86_64-linux-gnu dependencies
    g++-x86-64-linux-gnu gcc-x86-64-linux-gnu \
    # flatpak dependencies
    flatpak flatpak-builder binutils elfutils patch unzip xz-utils zstd \
    && apt clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && sh -c 'echo "en_US.UTF-8 UTF-8" > /etc/locale.gen' \
    && locale-gen \
    && update-locale LANG=en_US.UTF-8

ENV FLATPAK_RUNTIME_VERSION=24.08
RUN flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo \
    && flatpak install -y flathub org.freedesktop.Platform//${FLATPAK_RUNTIME_VERSION} \
    && flatpak install -y flathub org.freedesktop.Sdk//${FLATPAK_RUNTIME_VERSION}

# Install nodejs for Github Actions
RUN curl -fsSL https://deb.nodesource.com/setup_23.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install Go
ENV PATH=${PATH}:/usr/local/go/bin:${HOME}/go/bin
ENV GOROOT=/usr/local/go
ENV GOPATH=${HOME}/go
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
      wget https://go.dev/dl/go${GOLANG_VERSION}.linux-amd64.tar.gz -O go.tar.gz; \
    elif [ "$ARCH" = "aarch64" ]; then \
      wget https://go.dev/dl/go${GOLANG_VERSION}.linux-arm64.tar.gz -O go.tar.gz; \
    else \
      echo "Unsupported architecture: $ARCH"; exit 1; \
    fi && \
    rm -rf /usr/local/go && \
    tar -C /usr/local -xzf go.tar.gz && \
    rm go.tar.gz && \
    go install golang.org/x/mobile/cmd/gomobile@latest && \
    gomobile init

RUN git config --global user.email "czarek@cakewallet.com" \
    && git config --global user.name "CakeWallet CI"


# Install Android SDK commandline tools and emulator
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" != "x86_64" ]; then exit 0; fi \
    && wget -q https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_SDK_TOOLS_VERSION}_latest.zip -O android-sdk-tools.zip \
    && mkdir -p ${ANDROID_HOME}/cmdline-tools/ \
    && unzip -q android-sdk-tools.zip -d ${ANDROID_HOME}/cmdline-tools/ \
    && mv ${ANDROID_HOME}/cmdline-tools/cmdline-tools ${ANDROID_HOME}/cmdline-tools/latest \
    && chown -R root:root $ANDROID_HOME \
    && rm android-sdk-tools.zip \
    && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers \
    && yes | sdkmanager --licenses \
    && wget -O /usr/bin/android-wait-for-emulator https://raw.githubusercontent.com/travis-ci/travis-cookbooks/master/community-cookbooks/android-sdk/files/default/android-wait-for-emulator \
    && chmod +x /usr/bin/android-wait-for-emulator \
    && sdkmanager platform-tools \
    && mkdir -p ${HOME}/.android \
    && touch ${HOME}/.android/repositories.cfg \


# Handle emulator not being available on linux/arm64 (https://issuetracker.google.com/issues/227219818)
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" != "x86_64" ]; then exit 0; fi \
    && sdkmanager emulator

# Pre-install extra Android SDK dependencies in order to not have to download them for each build
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" != "x86_64" ]; then exit 0; fi \
    && yes | sdkmanager \
    "platforms;android-$ANDROID_PLATFORM_VERSION" \
    "build-tools;$ANDROID_BUILD_TOOLS_VERSION" \
    "platforms;android-33" \
    "platforms;android-34" \
    "platforms;android-35" \
    "build-tools;33.0.2" \
    "build-tools;33.0.1" \
    "build-tools;33.0.0" \
    "build-tools;35.0.0"

# Install extra NDK dependency for sp_scanner
ENV ANDROID_NDK_VERSION=28.2.13676358
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" != "x86_64" ]; then exit 0; fi \
    && yes | sdkmanager "ndk;$ANDROID_NDK_VERSION"

# Install dependencies for tests
# Comes from https://github.com/ReactiveCircus/android-emulator-runner
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" != "x86_64" ]; then exit 0; fi \
    && yes | sdkmanager \
    "system-images;android-29;default;x86_64" \
    "system-images;android-31;default;x86_64" \
    "platforms;android-29" \
    "platforms;android-31"

# Fake the KVM status so the Android emulator doesn't complain (that much)
RUN (addgroup kvm || true) && \
    adduser root kvm && \
    mkdir -p /etc/udev/rules.d/ && \
    echo 'KERNEL=="kvm", GROUP="kvm", MODE="0666", OPTIONS+="static_node=kvm"' | tee /etc/udev/rules.d/99-kvm4all.rules

# Install rustup, rust toolchains, and cargo-ndk
ENV PATH=${HOME}/.cargo/bin:${PATH}
RUN curl https://sh.rustup.rs -sSf | bash -s -- -y && \
    cargo install cargo-ndk && \
    for toolchain in stable nightly; \
    do \
    for target in aarch64-linux-android armv7-linux-androideabi i686-linux-android x86_64-linux-android x86_64-unknown-linux-gnu aarch64-unknown-linux-gnu aarch64-unknown-linux-gnu; \
    do \
        rustup target add --toolchain $toolchain $target; \
    done \
    done

# Download and install Flutter
ENV HOME=${HOME}
ENV FLUTTER_HOME=${HOME}/sdks/flutter/${FLUTTER_VERSION}
ENV FLUTTER_ROOT=$FLUTTER_HOME
ENV PATH=${PATH}:${FLUTTER_HOME}/bin:${FLUTTER_HOME}/bin/cache/dart-sdk/bin

RUN git clone --branch ${FLUTTER_VERSION} https://github.com/flutter/flutter.git ${FLUTTER_HOME} && \
    cd ${FLUTTER_HOME} && \
    git fetch -a

RUN yes | flutter doctor --android-licenses \
    && flutter doctor \
    && chown -R root:root ${FLUTTER_HOME}

# Download and pre-cache necessary Flutter artifacts to speed up builds
RUN flutter precache
