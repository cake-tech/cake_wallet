## cw_polygon

Polygon (PoS) wallet module built on the shared EVM base (`cw_evm`). Supports native MATIC and ERC‑20 tokens with PolygonScan-backed history.

### Features

- EVM chain integration (chainId 137) with `web3dart`.
- Default ERC‑20 token list and per‑wallet token box.
- History via Etherscan v2 API (Polygon chain id) and internal tx support.
- Fee handling tuned for Polygon (priority fee floor, legacy gasPrice when needed).
- Create/sign native and ERC‑20 transfers; approvals; send/broadcast.
- Manage tokens (enable/disable, add/remove) and balances.
- Message signing and verification.

### Getting started

Provide secrets used by the shared EVM layer in `cw_evm/lib/.secrets.g.dart`:

```dart
// cw_evm/lib/.secrets.g.dart   (DO NOT COMMIT)
const String etherScanApiKey = 'YOUR_ETHERSCAN_KEY';
const String nowNodesApiKey = 'YOUR_NOWNODES_KEY'; // if using matic.nownodes.io
const String moralisApiKey = 'YOUR_MORALIS_KEY';   // optional: ERC20 metadata
```

Connect and sync:

```dart
final service = PolygonWalletService(walletInfoBox, true, client: PolygonClient());
final wallet = await service.create(EVMChainNewWalletCredentials(name: 'My POL', password: 'secret'));
await wallet.connectToNode(node: Node(uriRaw: 'polygon-rpc.com', isSSL: true));
await wallet.startSync();
```

### Usage

Send MATIC:

```dart
final pending = await wallet.createTransaction(
  EVMChainTransactionCredentials.single(
    address: '0x...',
    cryptoAmount: '0.2',
    currency: CryptoCurrency.maticpoly,
    priority: EVMChainTransactionPriority.medium,
  ),
);
final hash = await pending.commit();
```

Add an ERC‑20 token and refresh balance:

```dart
final token = await wallet.getErc20Token('0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174', 'polygon'); // USDC
if (token != null) {
  await wallet.addErc20Token(token);
}
```

### Additional information

- Toggle PolygonScan usage via shared preferences key `use_polygonscan`.
- See `lib/` for APIs: `PolygonClient`, `PolygonWallet`, `PolygonWalletService`.
