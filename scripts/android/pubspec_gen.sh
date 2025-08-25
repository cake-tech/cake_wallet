#!/bin/bash

MONERO_COM=monero.com
CAKEWALLET=cakewallet
HAVEN=haven

VALID_FLAGS=(
  --monero
  --bitcoin
  --litecoin
  --ethereum
  --polygon
  --nano
  --bitcoinCash
  --solana
  --tron
  --wownero
  --zano
  --decred
  --dogecoin
)

SELECTED_FLAGS=()
NON_COIN_FLAGS=()

is_valid_flag() {
  local flag="$1"
  for valid_flag in "${VALID_FLAGS[@]}"; do
    if [[ "$flag" == "$valid_flag" ]]; then
      return 0
    fi
  done
  return 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --*=*)
      echo "Please pass flags without = (e.g. '--bitcoin'), not '$1'"
      exit 1
      ;;

    --*)
      if is_valid_flag "$1"; then
        SELECTED_FLAGS+=("$1")
        shift
      else
        NON_COIN_FLAGS+=("$1")
        shift
      fi
      ;;

    *)
      echo "Unknown argument: $1"
      exit 1
      ;;
  esac
done

if [[ ${#SELECTED_FLAGS[@]} -eq 0 ]]; then
  if [[ -z "$APP_ANDROID_TYPE" ]]; then
    echo "Please set APP_ANDROID_TYPE environment variable"
    exit 1
  fi

  case $APP_ANDROID_TYPE in
    $MONERO_COM)
      SELECTED_FLAGS=("--monero")
      ;;
    $CAKEWALLET)
      SELECTED_FLAGS=(
        "--monero"
        "--bitcoin"
        "--litecoin"
        "--bitcoinCash"
        "--ethereum"
        "--polygon"
        "--nano"
        "--solana"
        "--tron"
        "--wownero"
        "--zano"
        "--decred"
        "--dogecoin"
      )
      ;;
  esac

  echo "Using default for $APP_ANDROID_TYPE: ${SELECTED_FLAGS[*]}"
else
  echo "Using individual flags: ${SELECTED_FLAGS[*]}"
fi

cd ../..
cp -rf pubspec_description.yaml pubspec.yaml
flutter pub get
dart run tool/generate_pubspec.dart
flutter pub get

if [[ ${#NON_COIN_FLAGS[@]} -gt 0 ]]; then
  echo "Configuring CW with additional flags: ${NON_COIN_FLAGS[*]}"
  dart run tool/configure.dart "${SELECTED_FLAGS[@]}" "${NON_COIN_FLAGS[@]}"
else
  echo "Configuring CW without additional flags"
  dart run tool/configure.dart "${SELECTED_FLAGS[@]}"
fi

for flag in "${SELECTED_FLAGS[@]}"; do
  if [[ "$flag" == "--bitcoin" ]]; then
    cd cw_bitcoin
    dart run tool/generate_pubspec.dart

    if [[ ${#NON_COIN_FLAGS[@]} -gt 0 ]]; then
      echo "Configuring Bitcoin with additional flags: ${NON_COIN_FLAGS[*]}"
      dart run tool/configure.dart "${NON_COIN_FLAGS[@]}"
    else
      echo "Configuring Bitcoin without additional flags"
      dart run tool/configure.dart
    fi

    cd ..
    break
  fi
done

cd scripts/android
