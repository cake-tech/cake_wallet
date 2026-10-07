## cw_dash

Dash wallet module using the shared Bitcoin Electrum implementation (`cw_bitcoin`) configured for Dash mainnet.

### Features

- BIP-39 keys, Dash HD path `m/44'/5'/0'`.
- Electrum node sync: address set, UTXOs, balances.
- Create/sign/broadcast P2PKH transactions with configurable fee rate.
- Address book and index management, message signing.

### Usage

Create via `DashWalletService` (wired through `lib/dash/`), then send:

```dart
final pending = await wallet.createTransaction(
  outputs: [
    BitcoinTransactionOutput(
      address: 'X...',
      amount: 100000000, // 1 DASH in duffs
    ),
  ],
  feeRate: wallet.feeRate(DashTransactionPriority.medium),
);
final txHash = await pending.commit();
```

### Notes

- Mainnet, P2PKH only. No hardware wallets, WIF restore, InstantSend, or testnet.
- Relies on `cw_bitcoin` for UTXO selection and persistence.
