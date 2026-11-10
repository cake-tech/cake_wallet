# cw_minotari - Minotari (XTM) Integration for Cake Wallet

Cake Wallet integration package for the Minotari (Tari) cryptocurrency.

## Overview

This package provides full wallet functionality for Minotari (XTM) including:
- Wallet creation and restoration (24-word BIP39 mnemonic)
- Blockchain synchronization via streaming scanner
- Balance tracking (available, pending incoming, pending outgoing)
- Transaction history with full details
- Transaction sending with fee estimation

## Architecture

```
cw_minotari/
├── lib/
│   ├── cw_minotari.dart           # Package exports
│   ├── minotari_wallet.dart       # Main wallet (MobX store)
│   ├── minotari_wallet_service.dart   # Wallet lifecycle management
│   ├── minotari_ffi.dart          # Rust FFI wrapper
│   ├── minotari_balance.dart      # Balance model
│   ├── minotari_transaction_*.dart    # Transaction models
│   ├── minotari_wallet_addresses.dart # Address management
│   ├── pending_minotari_transaction.dart  # Pending TX
│   └── src/rust/                  # FRB bindings from the cw_tari_wallet release
├── android/                       # Android plugin + jniLibs
├── ios/                           # iOS plugin + xcframework
├── macos/                         # macOS FFI plugin (podspec) + framework
├── linux/                         # Linux FFI plugin (CMake) + .so
└── windows/                       # Windows FFI plugin (CMake) + .dll
```

### Key Components

| Component | Purpose |
|-----------|---------|
| `MinotariWallet` | Main wallet class, extends `WalletBase`, uses MobX for reactive state |
| `MinotariWalletService` | Factory for creating/opening/restoring wallets |
| `MinotariFfi` | Wrapper around Flutter Rust Bridge bindings |
| `MinotariBalance` | Balance model with available/pending amounts |
| `MinotariTransactionInfo` | Transaction model compatible with Cake Wallet UI |

## Setup Instructions

### Prerequisites

- Flutter SDK 3.32+
- `curl`, `unzip`, `sha256sum` and `git`
- For iOS/macOS: Xcode 15+, CocoaPods

No Rust toolchain is needed: the native libraries and Dart bindings come prebuilt
from a pinned [cw_tari_wallet release](https://github.com/tari-project/cw_tari_wallet/releases).

### 1. Fetch the native libraries and bindings

```bash
# From cake_wallet root; any of android ios macos linux windows
./scripts/prepare_minotari.sh android ios
```

This script:
- Checks that the pinned tag still points at the pinned commit
- Downloads `SHA256SUMS` of the pinned release and checks it against the pinned digest
- Downloads `cw_tari_wallet-<tag>-<platform>.zip` and `cw_tari_wallet-<tag>-dart.zip`, and fails
  if either does not match `SHA256SUMS`; nothing in `cw_minotari` is replaced until every zip is verified
- Unpacks the Dart bindings into `lib/src/rust/` and the libraries into:

| Platform | Output |
|----------|--------|
| Android | `android/src/main/jniLibs/{arm64-v8a,armeabi-v7a,x86_64}/librust_lib_flutter_rust_wallet.so` |
| iOS | `ios/Frameworks/rust_lib_flutter_rust_wallet.xcframework` |
| macOS | `macos/Frameworks/rust_lib_flutter_rust_wallet.framework` (wraps the release dylib) |
| Linux | `linux/lib/librust_lib_flutter_rust_wallet.so` (host architecture) |
| Windows | `windows/lib/rust_lib_flutter_rust_wallet.dll` |

For Cake Wallet it is run by the platforms' `build_all.sh`, `scripts/linux/build_cake_release.sh`,
`cakewallet.bat` (Windows), the build guides in `docs/builds/` and the CI workflows.
`scripts/ci/test_prepare_minotari.sh` tests its verification offline.

### 2. Bump the pinned cw_tari_wallet version

Edit the top of `scripts/prepare_minotari.sh`:

```bash
CW_TARI_WALLET_TAG="v0.2.0"                     # release tag
CW_TARI_WALLET_SHA="7d8d1c4d..."                # commit the tag points at
CW_TARI_WALLET_SUMS_SHA256="..."                # sha256sum of the release's SHA256SUMS
```

Get the digest with `gh release download <tag> -R tari-project/cw_tari_wallet -p SHA256SUMS && sha256sum SHA256SUMS`,
then rerun `prepare_minotari.sh`. The Dart bindings always come from the same release, so they
match the libraries.

Every `prepare_minotari.sh` run replaces `lib/src/rust`, deleting the generated
`scanner.freezed.dart`; run `./model_generator.sh` (or `dart run build_runner build` in
`cw_minotari`) afterwards.

### 3. Configure Build

```bash
# Enable Minotari in Cake Wallet build
source ./scripts/android/app_env.sh cakewallet
./scripts/android/app_config.sh
```

The `--minotari` flag is included in platform config scripts.

### 4. Generate Code

```bash
cd cw_minotari && flutter pub get && dart run build_runner build
cd .. && ./model_generator.sh
```

## Technical Details

### Amount Units

- Base unit: **microTari (µT)**
- 1 XTM = 1,000,000 microTari
- Decimals: 6
- Internal arithmetic uses `int` (fits in int64)

### Address Format

RFC-0155 compliant Base58-encoded addresses:
- Simplified: ~47 characters
- Standard: ~91 characters
- With payment ID: up to ~440 characters

Validation pattern: `[123Hdf][234678][1-9A-HJ-NP-Za-km-z]{45,448}`

### Network Configuration

Wallets use `mainNet`. Testnet wallets map to `esmeralda`, which the release libraries
(built for the mainnet network group) reject, so testnet Minotari wallets don't work yet.

### Blockchain Sync

Uses streaming scanner (not polling):

```dart
final stream = _ffi.startScan(
  baseNodeAddress: nodeUrl,
  passphrase: passphrase,
  continuous: false,  // One-time sync
  batchSize: 1000,
  pollIntervalSeconds: 5,
);
```

Events: `ScanProgress`, `TransactionDiscovered`, `ScanComplete`, `ScanError`

### Transaction Sending

Streaming transaction flow:

```dart
final stream = _ffi.sendTransaction(
  seedWords: mnemonic,
  passphrase: passphrase,
  recipientAddress: address,
  amount: BigInt.from(amountMicroTari),
  baseNodeUrl: nodeUrl,
  paymentId: optionalPaymentId,
);
```

Stages: `Preparing`, `Broadcasting`, `Confirming`, `Completed`

### Fee Estimation

Three priority levels:
- `MinotariTransactionPriority.slow` (raw: 0)
- `MinotariTransactionPriority.medium` (raw: 1, default)
- `MinotariTransactionPriority.fast` (raw: 2)

Fee calculated by Rust library based on transaction size and priority.

Note: Fee doesn't depend on amount, so we request estimate for 0 amount value.

## Dependencies

### Dart
- `cw_core` - Cake Wallet core abstractions
- `mobx` - Reactive state management
- `flutter_rust_bridge: 2.11.1` - FFI code generation

### Native (cw_tari_wallet)
- Prebuilt `rust_lib_flutter_rust_wallet` from the pinned release (bundles its own SQLite, uses rustls)

## Proxy Layer

Main app uses proxy pattern for conditional compilation:

```
lib/minotari/
├── minotari.dart      # Abstract interface (generated by configure.dart)
└── cw_minotari.dart   # Implementation
```

Access via global singleton:
```dart
import 'package:cake_wallet/minotari/minotari.dart';

final service = minotari!.createMinotariWalletService();
```

## Default Node

```yaml
# assets/minotari_node_list.yml
- uri: rpc.tari.com
  is_default: true
  useSSL: true
```

## Block Explorer

Transaction details link to: `https://explore.tari.com/search?hash={payref}`

Uses first payment reference (payref) from transaction for lookup.

## What's Working

- Wallet creation with 24-word mnemonic generation
- Wallet restoration from mnemonic
- Mainnet wallets (testnet wallets are not supported by the release libraries)
- Blockchain synchronization via scanner
- Balance updates (available, pending incoming, pending outgoing)
- Transaction history with full details
- Address generation and display
- Address validation (RFC-0155 compliant)
- Fee estimation with priority levels
- Transaction sending
- Mnemonic storage and backup (.keys file)
- Prebuilt native libraries for Android (arm64, armv7, x86_64), iOS, macOS, Linux (x86_64, aarch64) and Windows

## Known Limitations

1. **Sync progress:** Shows "Synchronizing" without percentage (chain tip not exposed by scanner)
2. **Message signing:** Not implemented (requires Rust FFI extension)
3. **Hardware wallets:** Not supported
4. **Keys-based restore:** Not supported (mnemonic only)
5. **Buy/sell providers:** No providers currently support XTM

## Resources

- [Cake Wallet Integration Guide](../docs/ADDING_NEW_WALLET_TYPES.md)
- [cw_tari_wallet Repository](https://github.com/tari-project/cw_tari_wallet)
- [Tari Protocol](https://tari.com)
- [Tari Block Explorer](https://explore.tari.com)
- [Flutter Rust Bridge](https://cjycode.com/flutter_rust_bridge/)
