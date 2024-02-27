IOS="ios"
ANDROID="android"

PLATFORMS=($IOS $ANDROID)
PLATFORM=$1

if ! [[ " ${PLATFORMS[*]} " =~ " ${PLATFORM} " ]]; then
    echo "specify platform: ./configure_cake_wallet.sh ios|android"
    exit 1
fi

if [ "$PLATFORM" == "$IOS" ]; then
    echo "Configuring for iOS"
    cd scripts/ios
fi

if [ "$PLATFORM" == "$ANDROID" ]; then
    echo "Configuring for Android"
    cd scripts/android
fi

source ./app_env.sh cakewallet
./app_config.sh
cd ../.. && flutter pub get
flutter packages pub run tool/generate_localization.dart
cd cw_core && flutter pub get && flutter packages pub run build_runner build --delete-conflicting-outputs && cd ..
cd cw_evm && flutter pub get && flutter packages pub run build_runner build --delete-conflicting-outputs && cd ..
cd cw_monero && flutter pub get && flutter packages pub run build_runner build --delete-conflicting-outputs && cd ..
cd cw_bitcoin && flutter pub get && flutter packages pub run build_runner build --delete-conflicting-outputs && cd ..
cd cw_haven && flutter pub get && flutter packages pub run build_runner build --delete-conflicting-outputs && cd ..
cd cw_nano && flutter pub get && flutter packages pub run build_runner build --delete-conflicting-outputs && cd ..
cd cw_bitcoin_cash && flutter pub get && flutter packages pub run build_runner build --delete-conflicting-outputs && cd ..
cd cw_solana && flutter pub get && flutter packages pub run build_runner build --delete-conflicting-outputs && cd ..
cd cw_ethereum && flutter pub get && cd ..
cd cw_polygon && flutter pub get && cd ..
flutter packages pub run build_runner build --delete-conflicting-outputs
