## cw_bitcoin_cash

Bitcoin Cash wallet module using the shared Electrum implementation configured for BCH mainnet. Includes CashAddr handling and BCH-specific fee/priority presets.

### Features

- Derive keys via BIP‑39; maintain receive/change address chains.
- Load/save snapshots of addresses, indices, and balances.
- Electrum connectivity and UTXO management.
- Create/sign/broadcast BCH transactions; calculate size-based fees by priority.
- CashAddr compatibility for addresses; migration of legacy snapshots.
- Message signing and verification.

### Getting started

Create/open via the app’s wallet service using `WalletType.bitcoinCash`. Ensure BCH Electrum nodes are configured.

```dart
final wallet = await BitcoinCashWallet.create(
  mnemonic: '...',
  password: 'secret',
  walletInfo: walletInfo,
  unspentCoinsInfo: unspentCoinsBox,
  encryptionFileUtils: encryption,
);
```

### Usage

Fee calculation and send:

```dart
final feeRate = wallet.feeRate(BitcoinCashTransactionPriority.medium);
final pending = await wallet.createTransaction(
  outputs: [
    BitcoinTransactionOutput(
      address: 'bitcoincash:qq...',
      amount: 10000, // satoshis
    ),
  ],
  feeRate: feeRate,
);
final txHash = await pending.commit();
```

### Additional information

- See `lib/src/` for: `BitcoinCashWallet`, `BitcoinCashWalletAddresses`, and helpers in `bitcoin_cash_base.dart`.
- Snapshot migration and CashAddr normalization are handled during open.
