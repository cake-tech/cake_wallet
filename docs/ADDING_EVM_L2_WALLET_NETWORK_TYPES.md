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
  - Default ERC20 tokens (optional but recommended)

## Architecture Overview

With the unified EVM architecture, all chains are managed through:
- **EvmChainRegistry**: Centralized registry for chain configurations
- **EVMChainWallet**: Single wallet class that handles all EVM chains via `selectedChainId`
- **ChainId-based operations**: All operations use `chainId` instead of `WalletType`
- **Backward compatibility**: Old wallet types (ethereum, polygon, base, arbitrum) still work

**Key Principle**: New chains should use `WalletType.evm` and be identified by their `chainId`. Old chains maintain backward compatibility.

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
    nativeCurrency: CryptoCurrency.op, // Must exist in cw_core/lib/crypto_currency.dart
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
  WalletType.evm, // Use WalletType.evm for new chains (or old type if backward compatibility needed)
  'OP', // Native currency symbol
);
```

**Notes**:
- For **new chains**, use `WalletType.evm` (unified type)
- For **backward compatibility** with existing wallets, you can map to an old `WalletType` (e.g., `WalletType.optimism` if it exists)
- The registry automatically creates mappings: `chainId` → `WalletType`, `tag` → `chainId`, `caip2` → `chainId`
- If the chain uses a standard EVM client, you can use the default `EVMChainClient` (no custom client needed)

### Step 2: Add Native Currency (If New)

**File**: `cw_core/lib/crypto_currency.dart`

If your chain's native currency doesn't exist, add it:

```dart
// Example: Adding Optimism native currency
static const CryptoCurrency op = CryptoCurrency(
  name: 'Optimism',
  title: 'OP',
  raw: 126,
  iconPath: 'assets/images/op.png', // Add icon asset
  tag: 'OP',
  decimals: 18,
);
```

**Notes**:
- The `tag` should match the symbol used in the registry
- Add the currency icon to `assets/images/`
- Update currency lists if needed (e.g., `all`, `fiat`, etc.)

### Step 2b: Wire Currency ↔ chainId Mappings

The unified EVM and PayAnything flows rely on a **two-way mapping** between
`CryptoCurrency` and `chainId`.

**File**: `cw_core/lib/currency_for_wallet_type.dart`

1. **Map `chainId` → `CryptoCurrency`** in `getCryptoCurrencyByChainId`:

```dart
CryptoCurrency getCryptoCurrencyByChainId(int chainId) {
  switch (chainId) {
    case 1:
      return CryptoCurrency.eth;
    case 137:
      return CryptoCurrency.maticpoly;
    case 8453:
      return CryptoCurrency.baseEth;
    case 42161:
      return CryptoCurrency.arbEth;
    case 10:
      return CryptoCurrency.op; // NEW: Optimism
    default:
      return CryptoCurrency.eth;
  }
}
```

2. **Map `CryptoCurrency` → `chainId`** in `getChainIdByCryptoCurrency`:

```dart
int? getChainIdByCryptoCurrency(CryptoCurrency currency) {
  switch (currency) {
    case CryptoCurrency.eth:
      return 1;
    case CryptoCurrency.maticpoly:
      return 137;
    case CryptoCurrency.baseEth:
      return 8453;
    case CryptoCurrency.arbEth:
      return 42161;
    case CryptoCurrency.op: // NEW: Optimism
      return 10;
    default:
      return null;
  }
}
```

**Why this matters**:
- `UniversalAddressDetector` and `PaymentViewModel` use these helpers to
  derive `chainId` from detected currencies (QR codes, URIs, raw EVM
  addresses).
- The EVM PayAnything flow and `EVMPaymentFlowBottomSheet` depend on having
  the correct `chainId` for network and token selection.

### Step 3: Create Default Tokens File (Optional but Recommended)

**File**: `cw_evm/lib/tokens/optimism_tokens.dart` (example)

Create a new file following the pattern of existing token files:

```dart
import 'package:cw_core/erc20_token.dart';

/// Default ERC20 tokens for Optimism Mainnet
class OptimismTokens {
  static List<Erc20Token> get tokens {
    return [
      Erc20Token(
        name: 'USD Coin',
        symbol: 'USDC',
        contractAddress: '0x7f5c764cbc14f9669b88837ca1490cca17c31607',
        decimal: 6,
        enabled: true,
      ),
      Erc20Token(
        name: 'Tether USD',
        symbol: 'USDT',
        contractAddress: '0x94b008aa00579c1307b0ef2c499ad98a8ce58e58',
        decimal: 6,
        enabled: true,
      ),
      // Add more default tokens
    ];
  }
}
```

**File**: `cw_evm/lib/evm_chain_default_tokens.dart`

Add your chain's tokens to the switch statement:

```dart
static List<Erc20Token> getDefaultTokensByChainId(int chainId) {
  return switch (chainId) {
    1 => EthereumTokens.tokens,
    137 => PolygonTokens.tokens,
    8453 => BaseTokens.tokens,
    42161 => ArbitrumTokens.tokens,
    10 => OptimismTokens.tokens, // NEW
    _ => [],
  };
}
```

**Notes**:
- Default tokens are automatically loaded when a wallet is created or when switching to that chain
- Users can add/remove tokens later via the UI
- Only include well-known, verified tokens

### Step 4: Update Chain Utilities (If Needed)

**File**: `cw_evm/lib/utils/evm_chain_utils.dart`

Add chain-specific logic if your chain has special requirements:

#### 4.1 Priority Fees

```dart
static int getTotalPriorityFee(EVMChainTransactionPriority priority, int chainId) {
  return switch (chainId) {
    1 => _ethereumPriorityFee(priority),
    137 => _polygonPriorityFee(priority),
    8453 => _basePriorityFee(priority),
    42161 => 0, // Arbitrum doesn't use priority fees
    10 => _optimismPriorityFee(priority), // NEW - if custom logic needed
    _ => _ethereumPriorityFee(priority), // Default to Ethereum logic
  };
}

static bool hasPriorityFee(int chainId) {
  return switch (chainId) {
    42161 => false, // Arbitrum doesn't use priority fees
    10 => true, // Optimism uses priority fees
    _ => true,
  };
}
```

#### 4.2 ERC20 Tokens Box Name

```dart
static String getErc20TokensBoxName(String walletName, int chainId) {
  final sanitizedName = walletName.replaceAll(" ", "_");
  return switch (chainId) {
    1 => "${sanitizedName}_${Erc20Token.ethereumBoxName}",
    137 => "${sanitizedName}_${Erc20Token.polygonBoxName}",
    8453 => "${sanitizedName}_${Erc20Token.baseBoxName}",
    42161 => "${sanitizedName}_${Erc20Token.arbitrumBoxName}",
    10 => "${sanitizedName}_${Erc20Token.optimismBoxName}", // NEW - if custom box name needed
    _ => "${sanitizedName}_${Erc20Token.ethereumBoxName}", // Default
  };
}
```

**Note**: If you don't add a case, it will use the default (Ethereum box name pattern). Only add if you need a specific box name.

#### 4.3 Transaction History File Name

```dart
static String getTransactionHistoryFileName(int chainId) {
  return switch (chainId) {
    1 => 'transactions.json',
    137 => 'polygon_transactions.json',
    8453 => 'base_transactions.json',
    42161 => 'arbitrum_transactions.json',
    10 => 'optimism_transactions.json', // NEW
    _ => 'transactions_$chainId.json', // Generic format for other chains
  };
}
```

#### 4.4 Scan Provider Preference Key

```dart
static String getScanProviderPreferenceKey(int chainId) {
  return switch (chainId) {
    1 => 'use_etherscan',
    137 => 'use_polygonscan',
    8453 => 'use_basescan',
    42161 => 'use_arbiscan',
    10 => 'use_optimismscan', // NEW
    _ => 'use_etherscan', // Default
  };
}
```

#### 4.5 Default Token Tag

```dart
static String getDefaultTokenTag(int chainId) {
  return switch (chainId) {
    1 => 'ETH',
    137 => 'POL',
    8453 => 'ETH',
    42161 => 'ETH',
    10 => 'OP', // NEW
    _ => 'ETH', // Default
  };
}
```

#### 4.6 Fee Currency Symbol

```dart
static String getFeeCurrency(int chainId) {
  return switch (chainId) {
    1 => 'ETH',
    137 => 'MATIC', // Polygon uses MATIC, not POL
    8453 => 'ETH',
    42161 => 'ETH',
    10 => 'ETH', // Optimism uses ETH
    _ => 'ETH', // Default
  };
}
```

**Note**: This is used in transaction fetching APIs. Polygon uses 'MATIC' even though the currency tag is 'POL'.

#### 4.7 Default Token Symbol

```dart
static String getDefaultTokenSymbol(int chainId) {
  return switch (chainId) {
    1 => 'ETH',
    137 => 'MATIC',
    8453 => 'ETH',
    42161 => 'ETH',
    10 => 'ETH', // Optimism uses ETH
    _ => 'ETH', // Default
  };
}
```

### Step 5: Create Custom Client (Only If Needed)

**Only needed if the chain requires custom transaction/balance fetching behavior**

Most chains can use the default `EVMChainClient` which handles:
- Standard ERC20 token operations
- EIP-1559 transactions
- Internal transactions
- Balance fetching

**File**: `cw_evm/lib/clients/optimism_client.dart` (example)

```dart
import 'package:cw_evm/clients/evm_chain_client.dart';

class OptimismClient extends EVMChainClient {
  OptimismClient() : super(chainId: 10);
  
  // Only override methods if custom behavior is needed
  // For example, if Optimism has special transaction formatting:
  
  // @override
  // Future<List<EVMChainTransactionModel>> fetchTransactions(...) async {
  //   // Custom implementation
  // }
}
```

**File**: `cw_evm/lib/clients/evm_chain_client_factory.dart`

Add your custom client to the factory:

```dart
static EVMChainClient createClient(int chainId) {
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
      // Default client works for most chains
      return EVMChainClient(chainId: chainId);
  }
}
```

**Note**: If you don't create a custom client, the default `EVMChainClient(chainId: chainId)` will be used automatically.

### Step 6: Add Node List YAML

**File**: `assets/optimism_node_list.yml`

Create a YAML file with default RPC endpoints:

```yaml
- uri: mainnet.optimism.io
  useSSL: true
  isEnabledForAutoSwitching: true
- uri: optimism.publicnode.com
  useSSL: true
  isEnabledForAutoSwitching: true
- uri: 1rpc.io/op
  useSSL: true
  isEnabledForAutoSwitching: true
```

**File**: `lib/entities/node_list.dart`

Add node loading for your chain:

```dart
Future<List<Node>> loadDefaultNodes(WalletType type) async {
  String path;
  switch (type) {
    // ... existing cases ...
    case WalletType.evm: // For new chains using WalletType.evm
      // Nodes are loaded based on chainId, not WalletType
      // This is handled automatically by the node switching service
      return [];
    case WalletType.optimism: // Only if using old WalletType for backward compatibility
      path = 'assets/optimism_node_list.yml';
      break;
  }
  // ... rest of the function ...
}
```

**Note**: For `WalletType.evm` wallets, nodes are managed dynamically based on `chainId`. The node switching service automatically loads the correct nodes.

### Step 7: Update DI Registration (If Using Old WalletType)

**Only needed if you're adding a new `WalletType` enum value for backward compatibility**

**File**: `cw_core/lib/wallet_type.dart`

If you need a new `WalletType` (not recommended for new chains):

```dart
enum WalletType {
  // ... existing types ...
  @HiveField(19) // Next available field ID
  optimism, // Only if needed for backward compatibility
}
```

**File**: `lib/di.dart`

Add your wallet type to the `WalletService` factory:

```dart
factory WalletService(WalletType type, bool isDirect) {
  switch (type) {
    // ... existing cases ...
    case WalletType.optimism: // Only if using old WalletType
      return evm!.createEVMWalletService(type, isDirect);
    case WalletType.evm: // For new unified wallets
      return evm!.createEVMWalletService(type, isDirect);
  }
}
```

**Note**: **For new chains, use `WalletType.evm`** - no DI changes needed! The unified proxy already handles all EVM chains.

### Step 8: Add Erc20Token Box Name Constant (If Needed)

**File**: `cw_core/lib/erc20_token.dart`

If you need a specific box name pattern:

```dart
class Erc20Token extends CryptoCurrency {
  // ... existing code ...
  
  static const String optimismBoxName = 'optimism_erc20_tokens';
}
```

**Note**: Only needed if you want a custom box name. Otherwise, the default pattern will be used.

## What Happens Automatically

Once you've completed the steps above, the following will work automatically:

✅ **Chain appears in dropdown** - The chain selection UI (`EvmSwitcher`) automatically shows your new chain from the registry  
✅ **Wallet creation** - Users can create `WalletType.evm` wallets and switch to your chain  
✅ **Chain switching** - Users can switch between chains seamlessly  
✅ **All operations** - Balance fetching, transaction sending, etc. all work  
✅ **Transaction filtering** - Transactions are automatically filtered by `chainId`  
✅ **Node connection** - Automatic node connection when switching chains (uses `chainId` to find correct nodes)  
✅ **Balance updates** - Automatic balance refresh when switching chains  
✅ **ERC20 tokens** - Default tokens are automatically loaded  
✅ **Transaction history** - Separate history files per chain  
✅ **Backward compatibility** - Old wallet types continue to work

## Testing Checklist

- [ ] Create a new `WalletType.evm` wallet
- [ ] Switch to your new chain and verify it appears in the chain switcher
- [ ] Verify balances update correctly
- [ ] Switch between chains and verify balances update
- [ ] Send a transaction on the new chain
- [ ] Verify transactions are filtered correctly (only show transactions for current chain)
- [ ] Test node connection and switching
- [ ] Verify default tokens are loaded
- [ ] Test wallet backup/restore
- [ ] Verify transaction history is separate per chain
- [ ] Test on old wallet types (if applicable) to ensure backward compatibility

## Common Issues

### Issue: Chain doesn't appear in dropdown

**Solution**: 
- Verify the chain is registered in `EvmChainRegistry.initialize()`
- Check that `EvmChainRegistry().initialize()` is called during app startup
- Verify the registry is initialized before the UI tries to load chains

### Issue: Node connection fails

**Solution**: Check that:
- Node list YAML file exists and is properly formatted
- RPC endpoints are correct and accessible
- For `WalletType.evm` wallets, nodes are retrieved using `chainId` via `settingsStore.getCurrentNode(WalletType.evm, chainId: chainId)`
- Node switching service uses `isEVMCompatibleChain()` to handle all EVM wallets

### Issue: Transactions not showing

**Solution**: Verify:
- `chainId` is correctly set in transaction info
- Transaction filtering logic uses `chainId` (not `walletType`)
- Transactions are being saved with the correct `chainId` in `EVMChainTransactionHistory`
- `EVMChainTransactionInfo.fromJson()` correctly infers `chainId` for old transactions

### Issue: Default tokens not loading

**Solution**: 
- Verify tokens are added to `EVMChainDefaultTokens.getDefaultTokensByChainId()`
- Check that `addInitialTokens()` is called during wallet initialization
- Ensure token file follows the pattern: `class OptimismTokens { static List<Erc20Token> get tokens { ... } }`

### Issue: Balance not updating after chain switch

**Solution**:
- Verify `selectChain()` is called with the correct `chainId`
- Check that `initErc20TokensBox()` switches to the new chain's box
- Ensure `_fetchErc20Balances()` is called after chain switch
- Verify `erc20Currencies` getter handles closed boxes gracefully

### Issue: "Box has already been closed" error

**Solution**:
- This can happen during chain switching if code accesses `evmChainErc20TokensBox` while it's being closed
- Ensure all access to `evmChainErc20TokensBox` checks `isOpen` first
- The `erc20Currencies` getter should return empty list if box is closed
- Use try-catch blocks when accessing the box during async operations

## Summary

### Minimum Steps for Standard EVM Chain

1. **Add chain config to Registry** (Step 1) - Required
2. **Add native currency** (Step 2) - Required if currency doesn't exist
3. **Add default tokens** (Step 3) - Recommended
4. **Add node list YAML** (Step 6) - Required
5. **Update chain utilities** (Step 4) - Only if chain has special requirements

### For Chains with Custom Behavior

- Add **Step 5** (Custom Client) only if needed
- Add **Step 7** (DI Registration) only if using old `WalletType` (not recommended)
- Add **Step 8** (Box Name Constant) only if custom box name needed

### Key Points

✅ **Use `WalletType.evm` for new chains** - No need to create new `WalletType` enum values  
✅ **Everything is `chainId`-based** - All operations use `chainId`, not `walletType`  
✅ **Registry-driven** - Chain configuration is centralized in `EvmChainRegistry`  
✅ **Backward compatible** - Old wallet types (ethereum, polygon, base, arbitrum) still work  
✅ **No proxy files needed** - The unified `evm` proxy handles all chains  
✅ **Automatic chain switching** - Users can switch chains without creating new wallets  

### What You DON'T Need to Do

❌ Create a new `WalletType` enum value (use `WalletType.evm`)  
❌ Create a new proxy file (unified proxy handles all chains)  
❌ Create a new wallet service (unified service handles all chains)  
❌ Create a new wallet class (unified `EVMChainWallet` handles all chains)  
❌ Update view models (they work with any EVM chain via proxy)  
❌ Update UI components (chain switcher auto-populates from registry)  

**Key Point**: With the unified EVM architecture, adding new L2 chains is now much simpler - most chains only require Registry configuration and default tokens!
