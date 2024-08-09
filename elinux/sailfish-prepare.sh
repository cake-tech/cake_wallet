#!/bin/bash
# borrowed from https://github.com/MrCyjaneK/unnamed_monero_wallet/blob/master/elinux/sailfish_prepare.sh
# adjusted for cake

zypper in -f -y cmake ffmpeg-tools git clang libxkbcommon-devel wayland-protocols-devel wayland-client wayland-egl-devel make glibc-static

zypper in -f -y perl-IPC-Cmd curl ccache gperf cmake ffmpeg-tools git clang libxkbcommon-devel wayland-protocols-devel wayland-client wayland-egl-devel make glibc-static

git config --global --add safe.directory "*"

for i in gcc g++ ar ranlib;
do
    ln -s /usr/bin/$i /usr/bin/aarch64-meego-linux-gnu-$i
    ln -s /usr/bin/$i /usr/bin/aarch64-linux-gnu-$i
done

mkdir -p $HOME/flutter-elinux
git clone https://github.com/sony/flutter-elinux.git $HOME/flutter-elinux/$(uname -m)

FVM_VERSION=$(cat .github/workflows/pr_test_build_linux.yml | grep flutter-version | xargs | awk '{ print $2 }')
pushd "$HOME/flutter-elinux/$(uname -m)"
    git checkout $FVM_VERSION
popd

echo 'export PATH="$PATH:$HOME/flutter-elinux/$(uname -m)/bin"' >> $HOME/.bashrc
echo 'export PATH="$PATH:$HOME/flutter-elinux/$(uname -m)/flutter/bin"' >> $HOME/.bashrc
echo 'export PATH="$PATH:$HOME/.pub-cache/bin"' >> $HOME/.bashrc

git config --global --add safe.directory $HOME/flutter-elinux/$(uname -m)/flutter
git config --global --add safe.directory $HOME/flutter-elinux/$(uname -m)
git config --global --add safe.directory '*' # screw it.
git config --global user.email "ci@cakewallet.com"
git config --global user.name "Cake Wallet CI"

# not-so-temporary fix
curl -L --output /usr/include/linux/input-event-codes.h https://raw.githubusercontent.com/torvalds/linux/master/include/uapi/linux/input-event-codes.h
# end

if [[ ! -f "$HOME/SailfishOS/flutter-elinux/$(uname -m)/flutter-client" ]];
then
    echo "Flutter client not found, making one"
    pushd $(mktemp -d)
        git clone https://github.com/MrCyjaneK/flutter-embedded-linux
        cd flutter-embedded-linux
        mkdir build && cd build
        # hash in here doesn't matter, it is just to make the compiler happy.
        curl -L https://github.com/sony/flutter-embedded-linux/releases/download/c4cd48e186/elinux-arm64-release.zip --output elinux-arm64-release.zip
        unzip elinux-arm64-release.zip && rm elinux-arm64-release.zip
        cmake ..
        make -j$(nproc)
        mkdir -p $HOME/SailfishOS/flutter-elinux/$(uname -m)/
        cp flutter-client $HOME/SailfishOS/flutter-elinux/$(uname -m)/flutter-client
    popd
fi