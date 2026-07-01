# cw_core

Core abstractions and shared types for Cake Wallet modules.

## Highlights

- Wallet primitives: `WalletBase`, `WalletService`, `WalletInfo`, `WalletAddresses`.
- Transaction primitives: `TransactionInfo`, `TransactionHistoryBase`, directions/priorities.
- Currency models: `CryptoCurrency`, `Erc20Token`, SPL/TRON token types.
- Persistence helpers: Hive adapters, path helpers (`pathForWallet`), encrypted storage utils.
- Node representation (`Node`) and sync status types.

## Usage

Extend `WalletBase` for a new chain and provide a `WalletService` implementation to create/open/restore wallets.

```dart
class MyChainWallet extends WalletBase<MyBalance, MyHistory, MyTxInfo> { /* ... */ }
class MyChainWalletService extends WalletService<New, FromSeed, FromKeys, FromHardware> { /* ... */ }
```

See the chain modules (e.g., `cw_bitcoin`, `cw_evm`) for complete examples.
