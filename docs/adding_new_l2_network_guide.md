# Guide: Adding a New L2 Network

This guide provides step-by-step instructions for adding a new EVM-compatible L2 network to Cake Wallet.

## Prerequisites

- The network must be EVM-compatible
- You need the following information:
  - Chain ID
  - Network name
  - Native currency (usually a `CryptoCurrency` instance)
  - RPC endpoints
  - Block explorer URLs
  - Supported features (ERC20, EIP-1559, internal transactions, etc.)

## Step-by-Step Guide

### Step 1: Add Chain Configuration to Registry

**File**: `cw_evm/lib/evm_chain_registry.dart`

Add your chain configuration in the `initialize()` method:

```dart
// Example: Adding Optimism
_registerChain(
  const ChainConfig(
    chainId: 10, // Optimism mainnet
    name: 'Optimism',
    shortCode: 'op',
    caip2: 'eip155:10',
    nativeCurrency: CryptoCurrency.op, // Assuming this exists in cw_core
    capabilities: ChainCapabilities(
      supportsERC20: true,
      supportsEIP1559: true,
      supportsInternalTx: true,
      supportsSubscriptions: false,
      supportsENS: false,
    ),
    defaultRpcEndpoints: [
      'mainnet.optimism.io',
      'optimism.publicnode.com',
      // Add more RPC endpoints
    ],
    explorerUrls: [
      'https://optimistic.etherscan.io',
    ],
    feeModel: FeeModel(
      type: FeeType.eip1559,
      defaultGasLimit: 21000,
    ),
  ),
  WalletType.optimism, // If you're adding a new WalletType
  'OP', // Native currency symbol
);
```

**Notes**:
- If the chain uses a standard EVM client, you can use the default `EVMChainClient`
- If the chain needs custom behavior, you'll need to create a custom client (see Step 2)

### Step 2: Create Custom Client (Optional)

**Only needed if the chain requires custom client behavior**

**File**: `cw_evm/lib/clients/optimism_client.dart` (example)

```dart
import 'package:cw_evm/clients/evm_chain_client.dart';

class OptimismClient extends EVMChainClient {
  OptimismClient() : super(chainId: 10);
  
  // Override methods only if custom behavior is needed
  // Most chains can use the default EVMChainClient
}
```

**File**: `cw_evm/lib/evm_chain_client_factory.dart`

Add your custom client to the factory:

```dart
static EVMChainClient createClient(int chainId) {
  // ... existing code ...
  switch (chainId) {
    case 1: // Ethereum
      return EthereumClient();
    case 137: // Polygon
      return PolygonClient();
    case 8453: // Base
      return BaseClient();
    case 42161: // Arbitrum
      return ArbitrumClient();
    case 10: // Optimism - NEW
      return OptimismClient();
    default:
      return EVMChainClient(chainId: chainId);
  }
}
```

### Step 3: Add Default Tokens (Optional)

**File**: `cw_evm/lib/tokens/optimism_tokens.dart` (example)

```dart
import 'package:cw_core/erc20_token.dart';

List<Erc20Token> getOptimismDefaultTokens() {
  return [
    Erc20Token(
      name: 'USD Coin',
      symbol: 'USDC',
      contractAddress: '0x7f5c764cbc14f9669b88837ca1490cca17c31607',
      decimal: 6,
      enabled: true,
      tag: 'OP',
    ),
    // Add more default tokens
  ];
}
```

**File**: `cw_evm/lib/evm_chain_default_tokens.dart`

Add your chain's tokens:

```dart
static List<Erc20Token> getDefaultTokens(WalletType walletType) {
  switch (walletType) {
    case WalletType.ethereum:
      return getEthereumDefaultTokens();
    case WalletType.polygon:
      return getPolygonDefaultTokens();
    case WalletType.base:
      return getBaseDefaultTokens();
    case WalletType.arbitrum:
      return getArbitrumDefaultTokens();
    case WalletType.optimism: // NEW
      return getOptimismDefaultTokens();
    default:
      return [];
  }
}
```

### Step 4: Add WalletType (If New)

**File**: `cw_core/lib/wallet_type.dart`

Add your new wallet type to the enum:

```dart
enum WalletType {
  // ... existing types ...
  optimism,
}
```

**File**: `lib/entities/node_list.dart`

Add node loading for your chain:

```dart
Future<List<Node>> loadDefaultNodes(WalletType type) async {
  String path;
  switch (type) {
    // ... existing cases ...
    case WalletType.optimism: // NEW
      path = 'assets/optimism_node_list.yml';
      break;
  }
  // ... rest of the function ...
}
```

**File**: `lib/store/settings_store.dart`

Add node preference key and node management:

```dart
// Add preference key
static const optimismNodeId = 'optimism_node_id';

// Add node retrieval
final optimismNode = nodeSource.get(optimismNodeId);
if (optimismNode != null) {
  nodes[WalletType.optimism] = optimismNode;
}
```

### Step 5: Add Node List YAML

**File**: `assets/optimism_node_list.yml`

Create a YAML file with default RPC endpoints:

```yaml
- uri: mainnet.optimism.io
  useSSL: true
  isEnabledForAutoSwitching: true
- uri: optimism.publicnode.com
  useSSL: true
  isEnabledForAutoSwitching: true
```

### Step 6: Update DI Registration (If New WalletType)

**File**: `lib/di.dart`

Add your wallet type to the `WalletService` factory:

```dart
factory WalletService(WalletType type, bool isDirect) {
  switch (type) {
    // ... existing cases ...
    case WalletType.optimism: // NEW
      return evm!.createEVMWalletService(type, isDirect);
  }
}
```

### Step 7: Update Chain-Specific Utilities (If Needed)

**File**: `cw_evm/lib/utils/evm_chain_utils.dart`

Add any chain-specific utility methods if needed:

```dart
static String getDefaultTokenSymbol(WalletType walletType) {
  switch (walletType) {
    // ... existing cases ...
    case WalletType.optimism:
      return 'OP';
  }
}
```

## What Happens Automatically

Once you've completed the steps above, the following will work automatically:

✅ **Chain appears in dropdown** - The chain selection UI will automatically show your new chain  
✅ **Wallet creation** - Users can create wallets for your chain  
✅ **All operations** - Balance fetching, transaction sending, etc. all work  
✅ **Transaction filtering** - Transactions are automatically filtered by chainId  
✅ **Node connection** - Automatic node connection when switching chains  
✅ **Balance updates** - Automatic balance refresh when switching chains  

## Testing Checklist

- [ ] Create a new wallet for the chain
- [ ] Switch between chains and verify balances update
- [ ] Send a transaction on the new chain
- [ ] Verify transactions are filtered correctly
- [ ] Test node connection and switching
- [ ] Verify default tokens are loaded
- [ ] Test wallet backup/restore

## Common Issues

### Issue: Chain doesn't appear in dropdown

**Solution**: Verify the chain is registered in `EvmChainRegistry.initialize()`

### Issue: Node connection fails

**Solution**: Check that:
- Node list YAML file exists and is properly formatted
- RPC endpoints are correct and accessible
- Node is registered in `settings_store.dart`

### Issue: Transactions not showing

**Solution**: Verify:
- `chainId` is correctly set in transaction info
- Transaction filtering logic includes your chain
- Transactions are being saved with the correct `chainId`

## Summary

**Minimum Steps for Standard EVM Chain**:
1. Add chain config to Registry (Step 1)
2. Add node list YAML (Step 5)
3. Update DI if new WalletType (Step 6)

**For Chains with Custom Behavior**:
- Add Steps 2, 3, 4, 7 as needed

**Key Point**: With the unified EVM architecture, adding new L2 chains is now much simpler - most chains only require Registry configuration!

