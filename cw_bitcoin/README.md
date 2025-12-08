# cw_bitcoin

Bitcoin-family Electrum wallet implementation used by Cake Wallet (BTC, LTC and derivatives).

## Features

- Electrum client and wallet with address/UTXO management and snapshots.
- Derivation via BIP‑39; receive/change chains with per-coin configs.
- Create/sign/broadcast transactions; PSBT helpers and payjoin support.
- Transaction history, priorities, and size-based fee calculations.
- Hardware wallet support for BTC/LTC.

## Getting started

Use the module via app services (see `bitcoin_wallet_service.dart`, `litecoin_wallet_service.dart`). Ensure Electrum nodes are configured for the target coin.

```dart
final wallet = await BitcoinWallet.create(
  mnemonic: '...',
  password: 'secret',
  walletInfo: walletInfo,
  unspentCoinsInfo: unspentCoinsBox,
  encryptionFileUtils: encryption,
);
```

## Usage

Send BTC with medium priority:

```dart
final feeRate = wallet.feeRate(BitcoinTransactionPriority.medium);
final pending = await wallet.createTransaction(
  outputs: [BitcoinTransactionOutput(address: 'bc1...', amount: 50000)],
  feeRate: feeRate,
);
final txHash = await pending.commit();
```

See `lib/` for wallet/services, PSBT, and payjoin utilities.
