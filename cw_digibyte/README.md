# cw_digibyte

`cw_digibyte` packages the DigiByte-specific pieces of Cake Wallet's
Bitcoin-family Electrum integration. It mirrors the structure of the
existing `cw_bitcoin`, `cw_bitcoin_cash`, and `cw_dogecoin` packages so
that DigiByte wallets plug into the shared UTXO abstractions without
duplicating large amounts of code.

## Features

- DigiByte Electrum wallet implementation with the standard Cake Wallet
  persistence helpers (`WalletInfo`, `WalletKeysFile`, encrypted
  snapshots, etc.).
- Seed, mnemonic, and WIF/private-key restoration flows wired through the
  `DigibyteWalletService` for parity with other Bitcoin-derived coins.
- Transaction priority presets exposed as `DigibyteTransactionPriority`
  for fee selection and persistence.
- Wallet address management via `DigibyteWalletAddresses`, including
  automatic derivation for receive/change branches.

## Getting started

This package is not meant to be consumed independently on pub.dev. It is
published as part of Cake Wallet and is referenced via a relative path in
the main application. To experiment locally:

1. Run `flutter pub get` from the repository root to fetch dependencies.
2. Execute `dart run tool/configure.dart --monero --bitcoin --ethereum --polygon \
   --nano --bitcoinCash --solana --tron --wownero --zano --decred --dogecoin --digibyte`
   (or the corresponding platform script) so the generated proxy files in
   `lib/digibyte` are up to date.
3. Open the Flutter project as usual—`cw_digibyte` will be available to
   the app via the generated `lib/digibyte/digibyte.dart` proxy.

## Usage

Application code never instantiates the classes in this package directly.
Instead it interacts with the generated `Digibyte` proxy (see
`lib/digibyte/digibyte.dart`) which returns strongly typed credentials and
services. If you need to work with the wallet layer in isolation, you can
import `package:cw_digibyte/cw_digibyte.dart` and use the public exports:

```dart
import 'package:cw_digibyte/cw_digibyte.dart';

final credentials = DigibyteNewWalletCredentials(
  name: 'My DigiByte Wallet',
  password: 'secure passphrase',
);
```

The wallet implementation relies on Hive boxes for persistent storage and
expects to run inside the Cake Wallet environment.

## Additional information

DigiByte shares much of its behaviour with the other Bitcoin forks already
integrated into Cake Wallet. When making changes, consult the `cw_bitcoin`
and `cw_dogecoin` packages for reference implementations and keep the APIs
in sync so that the generated proxies remain consistent across coins.
