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
│   └── src/rust/api/              # Auto-generated FFI bindings
├── rust/                          # Rust submodule (cw_tari_wallet)
├── android/                       # Android plugin + native libs
└── ios/                           # iOS plugin + framework config
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
- Rust toolchain (stable + nightly)
- For Android: NDK r28+, `ANDROID_HOME` and `ANDROID_NDK_VERSION` env vars
- For iOS: Xcode 15+, CocoaPods

### 1. Initialize Rust Submodule

```bash
# From cake_wallet root
./scripts/prepare_minotari.sh
```

This script:
- Clones `cw_tari_wallet` to `cw_minotari/rust/`
- Runs `cargo build`
- Generates Dart FFI bindings via `flutter_rust_bridge_codegen`
- Builds native libraries (if platform tools available)

To update Rust dependencies:
```bash
./scripts/prepare_minotari.sh --update
```

### 2. Build Native Libraries 
NOTE: Don't need to call separately if you ran `prepare_minotari.sh`.

**Android:**
```bash
./scripts/android/build_minotari.sh
```

Output: `cw_minotari/android/src/main/jniLibs/{abi}/librust_lib_flutter_rust_wallet.so`

Architectures: `arm64-v8a`, `armeabi-v7a`, `x86_64`

**iOS:**
```bash
./scripts/ios/build_minotari.sh
```

Output: `cw_minotari/ios/Frameworks/rust_lib_flutter_rust_wallet.xcframework`

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

| Network | Use Case |
|---------|----------|
| `mainNet` | Production (default) |
| `esmeralda` | Testnet |
| `nextNet` | Development |

Network persisted in `WalletInfo.network` field.

Note: it's now hardcoded as `mainNet`.

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

### Rust (cw_tari_wallet)
- `minotari-wallet` - Tari wallet library fork
- `tari_common`, `tari_crypto` - Tari protocol
- `tokio` - Async runtime
- `r2d2_sqlite` - Connection pooling

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
- Network selection (mainnet/esmeralda/nextnet) with persistence
- Blockchain synchronization via scanner
- Balance updates (available, pending incoming, pending outgoing)
- Transaction history with full details
- Address generation and display
- Address validation (RFC-0155 compliant)
- Fee estimation with priority levels
- Transaction sending
- Mnemonic storage and backup (.keys file)
- Android native libraries (arm64, armv7, x86_64)
- iOS build configuration

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
