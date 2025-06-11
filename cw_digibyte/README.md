# cw_digibyte

A Dart package providing DigiByte wallet functionality for the Cake Wallet project.

## Getting started

1. From the repository root run `flutter pub get` to install dependencies.
2. Run `dart run build_runner build --delete-conflicting-outputs` if you need to
   regenerate any code.
3. Import `package:cw_digibyte/cw_digibyte.dart` in your project.

## Features

- Create new DigiByte wallets from a generated or existing mnemonic seed.
- Restore wallets using a mnemonic seed phrase.
- Restore wallets using a WIF (Wallet Import Format) private key.
- Open and manage existing DigiByte wallets.
- Hardware wallet support is **not** yet available.

For an overview of other wallet packages and general usage, see the main
[README](../README.md) and the documentation on
[adding new wallet types](../docs/NEW_WALLET_TYPES.md).
