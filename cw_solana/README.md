## cw_solana

Solana wallet module for Cake Wallet. Provides native SOL and SPL token support built on `on_chain/solana` with high-throughput RPC usage and safe transaction parsing.

### Features

- Connect to Solana RPC (Ankr/Chainstack/custom) via `SolanaRPC` over HTTP.
- Fetch SOL balances and aggregate SPL token balances across accounts.
- Parse and stream native and SPL token transactions (filters ATA-only and spam-like micro txs).
- Estimate fees per compiled message and enforce rent-exemption checks.
- Create/sign/broadcast SOL and SPL transfers; auto-create recipient ATA when necessary.
- Manage SPL tokens; fetch on-chain metadata (symbol/name) for unknown mints.
- Sign and verify messages.
- Node health checks for SOL and a known SPL token (USDC).

### Getting started

If you use hosted RPC providers, add a secrets file for keys (optional unless using those hosts):

```dart
// cw_solana/lib/.secrets.g.dart   (DO NOT COMMIT)
const String ankrApiKey = 'YOUR_ANKR_KEY';
const String chainStackApiKey = 'YOUR_CHAINSTACK_KEY';
```

Connect and sync:

```dart
final service = SolanaWalletService(walletInfoBox, true);
final wallet = await service.create(SolanaNewWalletCredentials(name: 'My SOL', password: 'secret'));
await wallet.connectToNode(node: Node(uriRaw: 'api.mainnet-beta.solana.com', isSSL: true));
await wallet.startSync();
final sol = wallet.balance[CryptoCurrency.sol]?.balance;
```

### Usage

Send SOL:

```dart
final pending = await wallet.createTransaction(
  SolanaTransactionCredentials.single(
    address: 'SoL...',
    cryptoAmount: '0.05',
    currency: CryptoCurrency.sol,
  ),
);
final sig = await pending.commit();
```

Add an SPL token by mint:

```dart
final token = await wallet.getSPLToken('EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v'); // USDC
if (token != null) {
  await wallet.addSPLToken(token);
}
```

### Additional information

- When using `rpc.ankr.com` or `solana-mainnet.core.chainstack.com`, the client reads API keys from `.secrets.g.dart`.
- See `lib/` for APIs: `SolanaWalletClient`, `SolanaWallet`, `SolanaWalletService`, and credential types.
