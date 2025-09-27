## cw_dogecoin

Dogecoin wallet module using the shared Bitcoin Electrum implementation (`cw_bitcoin`) configured for Dogecoin mainnet.

### Features

- Derive keys via BIP‑39; Dogecoin HD paths using `bitcoin_base`.
- Connect to Electrum nodes; maintain address sets and UTXOs.
- Create/sign/broadcast DOGE transactions with configurable fee rate.
- Address book and index management (receive/change, auto-generate settings).
- Message signing and verification.

### Getting started

Create/open via `DogecoinWalletService` in the app using `WalletType.dogecoin`. Ensure Electrum nodes are configured for Dogecoin.

```dart
final wallet = await DogeCoinWallet.create(
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

- See `lib/src/` for classes: `DogeCoinWallet`, `DogeCoinWalletAddresses`.
- Relies on core Electrum features in `cw_bitcoin` for UTXO selection and persistence.
