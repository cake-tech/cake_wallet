## cw_dash

Dash wallet module using the shared Bitcoin Electrum implementation (`cw_bitcoin`) configured for Dash mainnet.

### Features

- Derive keys via BIP‑39; Dash HD paths using `bitcoin_base`.
- Connect to Electrum nodes; maintain address sets and UTXOs.
- Create/sign/broadcast DOGE transactions with configurable fee rate.
- Address book and index management (receive/change, auto-generate settings).
- Message signing and verification.

### Getting started

Create/open via `DashWalletService` in the app using `WalletType.dash`. Ensure Electrum nodes are configured for Dash.

```dart
final wallet = await DashWallet.create(
  mnemonic: '...',
  password: 'secret',
  walletInfo: walletInfo,
  unspentCoinsInfo: unspentCoinsBox,
  encryptionFileUtils: encryption,
);
```

### Usage

Estimate fee and send:

```dart
final feeRate = wallet.feeRate(BitcoinCashTransactionPriority.medium); // example priority mapping
final pending = await wallet.createTransaction(
  outputs: [
    BitcoinTransactionOutput(
      address: 'D...',
      amount: 1 * 100000000, // 1 DOGE in koinu
    ),
  ],
  feeRate: feeRate,
);
final txHash = await pending.commit();
```

### Additional information

- See `lib/src/` for classes: `DashWallet`, `DashWalletAddresses`.
- Relies on core Electrum features in `cw_bitcoin` for UTXO selection and persistence.
