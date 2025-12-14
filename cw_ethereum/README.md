## cw_ethereum

Ethereum wallet module built on `cw_evm`. Supports native ETH and ERC‑20 tokens, with history fetched via Etherscan.

### Features

- EVM client specialized for Ethereum mainnet (chainId 1).
- Default ERC‑20 token list and wallet‑scoped token storage/migration.
- History via Etherscan v2 API (external, internal, and token transfers).
- EIP‑1559 fee support; gas estimation per transaction intent.
- Create/sign native and ERC‑20 transfers; approvals; broadcast.
- Manage ERC‑20 tokens and balances; metadata lookup when needed.
- Message signing and verification.
- Node health checks for native and USDC token balance.

### Getting started

Add shared EVM secrets (see `cw_evm` README):

```dart
// cw_evm/lib/.secrets.g.dart   (DO NOT COMMIT)
const String etherScanApiKey = 'YOUR_ETHERSCAN_KEY';
const String nowNodesApiKey = 'YOUR_NOWNODES_KEY'; // if using eth.nownodes.io
const String moralisApiKey = 'YOUR_MORALIS_KEY';   // optional
```

Connect and sync:

```dart
final service = EthereumWalletService(walletInfoBox, true, client: EthereumClient());
final wallet = await service.create(EVMChainNewWalletCredentials(name: 'My ETH', password: 'secret'));
await wallet.connectToNode(node: Node(uriRaw: 'eth.llamarpc.com', isSSL: true));
await wallet.startSync();
```

### Usage

Send ETH:

```dart
final pending = await wallet.createTransaction(
  EVMChainTransactionCredentials.single(
    address: '0x...',
    cryptoAmount: '0.05',
    currency: CryptoCurrency.eth,
    priority: EVMChainTransactionPriority.medium,
  ),
);
final hash = await pending.commit();
```

Add an ERC‑20 token and refresh balance:

```dart
final token = await wallet.getErc20Token('0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48', 'eth'); // USDC
if (token != null) {
  await wallet.addErc20Token(token);
}
```

### Additional information

- Toggle Etherscan usage via shared preferences key `use_etherscan`.
- See `lib/` for APIs: `EthereumClient`, `EthereumWallet`, `EthereumWalletService`.
