#!/bin/bash

set -e
set -x
cd $(dirname $0)
cd ..

source $HOME/.bashrc

if [[ "$(uname -m)" == "aarch64" ]];
then
    FLUTTER_ARCH="arm64"
fi

for coin in monero wownero;
do
    if [[ ! -f "scripts/monero_c/release/${coin}/$(gcc -dumpmachine)_libwallet2_api_c.so" ]];
    then
        git config --global --add safe.directory "*"
        for i in gcc g++ ar ranlib;
        do
            ln -s /usr/bin/$i /usr/bin/aarch64-meego-linux-gnu-$i
            ln -s /usr/bin/$i /usr/bin/aarch64-linux-gnu-$i
        done
        ./scripts/linux/build_monero_all.sh
    fi
done

pushd scripts
    ./gen_android_manifest.sh
popd
./configure_cake_wallet.sh linux

flutter-elinux pub get

flutter-elinux build elinux --release

cp $HOME/SailfishOS/flutter-elinux/$(uname -m)/flutter-client build/elinux/${FLUTTER_ARCH}/release/bundle/flutter-client

cat > build/elinux/${FLUTTER_ARCH}/release/bundle/cake_wallet <<EOF
#!/bin/bash
cd \$(dirname \$0)
killall flutter-client || true

LD_PRELOAD=\$PWD/lib/libflutter_engine.so ./flutter-client --bundle=\$PWD --fullscreen --force-scale-factor=3
EOF

chmod +x build/elinux/${FLUTTER_ARCH}/release/bundle/cake_wallet

rpmbuild -bb elinux/sailfishos.spec --define "_bundledir $PWD/build/elinux/${FLUTTER_ARCH}/release/bundle/" --define "_sourcedir $PWD"

cp $HOME/rpmbuild/RPMS/$(uname -m)/cake_wallet-*.rpm build/elinux/${FLUTTER_ARCH}/release/

