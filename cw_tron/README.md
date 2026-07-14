## cw_tron

TRON wallet module for Cake Wallet. Implements TRX and TRC-20 token support on top of `on_chain` (Tron), with transaction history and fee estimation via TronGrid.

### Features

- Connect to TRON nodes over HTTP(S) via `TronProvider`/`TronHTTPProvider`.
- Fetch TRX balance and TRC-20 token balances.
- Estimate fees using bandwidth/energy and memo fee; accounts for available account resources.
- Create and sign TRX and TRC-20 transfers (supports send-all and optional memo).
- Broadcast signed transactions.
- Load account history (TRX and TRC-20), filtering spam and TRC10-only events.
- Manage TRC-20 tokens: add/remove tokens and fetch token metadata.
- Sign/verify messages.
- Node health checks for both native and token balance endpoints.

### Getting started

Provide a TRON RPC endpoint and a TronGrid API key. Add a secrets file:

```dart
// cw_tron/lib/.secrets.g.dart   (DO NOT COMMIT)
const String tronGridApiKey = 'YOUR_TRONGRID_API_KEY';
```

Basic connect and sync:

```dart
final service = TronWalletService(walletInfoBox, client: TronClient(), isDirect: true);
final wallet = await service.create(TronNewWalletCredentials(name: 'My TRON', password: 'secret'));
await wallet.connectToNode(node: Node(uriRaw: 'api.trongrid.io', isSSL: true));
await wallet.startSync();
final trxBalance = wallet.balance[CryptoCurrency.trx];
```

### Usage

Send TRX:

```dart
final pending = await wallet.createTransaction(
  TronTransactionCredentials.single(
    address: 'T...',
    cryptoAmount: '1.5',
    currency: CryptoCurrency.trx,
  ),
);
final txHash = await pending.commit();
```

Add USDT (TRC-20):

```dart
final usdt = await wallet.getTronToken('TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t');
if (usdt != null) {
  await wallet.addTronToken(usdt);
}
```

### Additional information

- History and token queries use TronGrid; set `tronGridApiKey`.
- See `lib/` for APIs: `TronClient`, `TronWallet`, `TronWalletService`, and credential types.
