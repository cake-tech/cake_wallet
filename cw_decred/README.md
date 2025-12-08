# cw_decred

Decred wallet module that bridges to the native `libdcrwallet` via FFI. Provides high‑level methods to create/load wallets, sync, query balances/transactions, build and broadcast transactions, and sign/verify messages.

## Features

- FFI bindings to `libdcrwallet` with an isolate‑based request/response model.
- Initialize, create, load, close wallets; watch‑only creation.
- Start sync with optional peer list; query sync status and best block.
- Query balances, list transactions and unspents, rescan from height.
- Create signed transactions and broadcast raw transactions.
- Export wallet seed; change wallet password.
- Address management (new external address, default pubkey, address lists).
- Message signing and verification.

## Getting started

Ensure the platform library is available:

- Android/Linux: `libdcrwallet.so`
- Apple: embedded `cw_decred.framework/cw_decred`

Initialize and load a wallet:

```dart
final lib = await Libwallet.spawn();
await lib.initLibdcrwallet('', 'info');
await lib.loadWallet(jsonEncode({ /* libdcrwallet config */ }));
await lib.startSync('wallet.db', '');
final status = await lib.syncStatus('wallet.db');
```

## Usage

Create, sign, and broadcast a transaction:

```dart
final signed = await lib.createSignedTransaction('wallet.db', jsonEncode({
  // inputs/outputs and policy for libdcrwallet
}));
final txid = await lib.sendRawTransaction('wallet.db', signed);
```

## Additional information

- See `lib/api/` for the isolate wrapper (`libdcrwallet.dart`) and low‑level bindings.
- Errors are surfaced via the `PayloadResult` struct; some calls support `throwOnError` in higher‑level wrappers.
