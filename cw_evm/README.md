## cw_evm

Shared EVM-chain wallet foundation for Cake Wallet. Provides common client/wallet abstractions used by `cw_ethereum`, `cw_polygon`, and other EVM chains.

### What it provides

- `EVMChainClient` (Web3 + HTTP):
  - Connect to RPC (supports NowNodes short hosts with API key).
  - Read balance, gas price/base fee, estimate gas, send raw tx, watch tx.
  - Sign native and ERC‑20 transactions; build approval calldata.
  - Fetch ERC‑20 metadata (via Moralis) and balances.
- `EVMChainWallet`:
  - Derive keys from BIP‑39 or use private key / Ledger (`EvmLedgerCredentials`).
  - EIP‑1559 fee calculation with priority presets; Polygon-specific tuning.
  - ERC‑20 token box per wallet; add/remove tokens and maintain balances.
  - Transaction history assembly (external/internal + token transfers).
  - Message sign/verify helpers.
- `EVMChainWalletService`: common create/open/restore/rename lifecycle.

### Secrets

Create `cw_evm/lib/.secrets.g.dart` (do not commit):

```dart
const String nowNodesApiKey = '...';      // used for eth.nownodes.io / matic.nownodes.io
const String etherScanApiKey = '...';     // Etherscan v2 API key (incl. Polygon)
const String moralisApiKey = '...';       // optional, ERC-20 metadata lookup
```

### Extending to a new EVM chain

Create a client and wallet subclass:

```dart
class MyChainClient extends EVMChainClient {
  @override
  int get chainId => 8453; // example
  @override
  Uint8List prepareSignedTransactionForSending(Uint8List tx) => tx;
  @override
  Future<List<EVMChainTransactionModel>> fetchTransactions(String address, {String? contractAddress}) async { /* ... */ }
  @override
  Future<List<EVMChainTransactionModel>> fetchInternalTransactions(String address) async { /* ... */ }
}
```

Then wire into a `WalletService` similar to `EthereumWalletService`/`PolygonWalletService`.

### Additional information

- Uses `web3dart` under the hood and integrates with Cake Wallet’s `cw_core` types.
- See `lib/` for the reference implementation details.
