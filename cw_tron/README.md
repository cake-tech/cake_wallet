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

### Ledger wallets

Ledger TRON accounts use `m/44'/195'/{account}'/0/0`. Their public address and
derivation path allow opening and network synchronization without the device;
the wallet does not store a seed or private key. Connect the Ledger and open its
TRON app to confirm an address or sign a transfer.

Ledger transfers are limited to TRX and the mainnet USDT TRC-20 contract. Other
token contracts, memos, custom contracts, and transaction hash-signing are not
supported. USDT requires TRON app version 0.8.1 or later and custom contract
signing disabled on the device. Personal-message signing is unavailable for Ledger TRON wallets.
Software wallets retain their existing signing capabilities.

### Getting started

Provide a TRON RPC endpoint and a TronGrid API key. Add a secrets file:

```dart
// cw_tron/lib/.secrets.g.dart   (DO NOT COMMIT)
const String tronGridApiKey = 'YOUR_TRONGRID_API_KEY';
const String tronNowNodesApiKey = 'YOUR_NOWNODES_API_KEY';
```

For isolated development, the repository's `dart run tool/generate_new_secrets.dart`
creates ignored local configuration with placeholder service keys. Those placeholders
do not provide access to live API services; never commit the generated files.

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
