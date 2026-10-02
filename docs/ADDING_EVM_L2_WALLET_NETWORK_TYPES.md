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

**Key Principle**: There are two kinds of EVM network, and this guide is about the first one.

- **Built-in networks** are compiled into the app. Each has its own `WalletType` (ethereum, polygon, base, arbitrum, bsc) and its own native `CryptoCurrency`, and is registered in `EvmChainRegistry.initialize()`. Adding one is what the steps below describe.
- **Added networks** are the ones a user adds at runtime, from the ChainList feed or by hand. They all share `WalletType.evm`, and a wallet on one carries the chain in `WalletInfo.chainId`. Their settings live in the `EvmNetwork` SQLite table (`cw_core/lib/evm_network.dart`), and at start `evm.loadNetworks()` (called from `lib/main.dart`) registers every row with `EvmChainRegistry.registerAddedNetworkChain`, or only its native currency when the network is disabled. Their native currency is built at runtime and resolved through `EvmNativeCurrencies` (`cw_core/lib/currency_for_wallet_type.dart`). No code change is needed for a user to add one.

`WalletType.evm` is never used for a built-in network. `registerAddedNetworkCurrency` refuses a chain ID the registry already has as built-in.

`WalletType.evm` is stored three different ways, one per store. The `WalletInfo` table stores the enum index, which is 20. The `Node` table stores `serializeToInt` in `typeRaw`, which is 19. The Hive adapter in `cw_core/lib/wallet_type.part.dart` writes byte 20. A query has to use the encoding of the table it reads: `EvmNetworkService.walletCount` filters `WalletInfo` with `WalletType.evm.index`, and the node queries (`Node.getAllForEvmChain`, `Node.getDefaultForEvmChain`) filter with `serializeToInt(WalletType.evm)`. Mixing them up returns nothing and fails silently. `cw_core/test/wallet_type_codec_test.dart` pins all three.

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
    explorerUrls: [
      'https://optimistic.etherscan.io',
    ],
    feeModel: FeeModel(
      type: FeeType.eip1559,
      defaultGasLimit: 21000,
    ),
  ),
  WalletType.optimism, // The chain's own WalletType, see Step 7
  'OP', // Native currency symbol
);
```

**Notes**:
- A built-in chain always maps to its own `WalletType`. Never pass `WalletType.evm` here, that type belongs to the networks users add at runtime
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

Add the chain to the `_natives` map in `EvmNativeCurrencies`. Both
`getCryptoCurrencyByChainId` and `getChainIdByCryptoCurrency` read it:

```dart
static final Map<int, _EvmNative> _natives = {
  1: const _EvmNative(currency: CryptoCurrency.eth, walletType: WalletType.ethereum),
  // ...
  10: const _EvmNative(currency: CryptoCurrency.op, walletType: WalletType.optimism), // NEW
};
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
    8453 => 'use_base_scan',
    42161 => 'use_arbitrum_scan',
    10 => 'use_optimismscan', // NEW
    _ => 'use_etherscan', // Default
  };
}
```

#### 4.5 Token Tag and Fee Currency

Nothing to add. `getDefaultTokenTag` and `getFeeCurrency` read the `nativeCurrency` of the chain's `ChainConfig` from Step 1.

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
    case WalletType.optimism:
      path = 'assets/optimism_node_list.yml';
      break;
  }
  // ... rest of the function ...
}
```

**Note**: A built-in chain gets its nodes from its YAML list like any other wallet type. Added networks (`WalletType.evm`) have no YAML list: their node rows are written when the user enables or saves the network, keyed by `chainId`.

### Step 7: Add the WalletType and DI Registration

**Needed for every built-in chain**, since each one has its own `WalletType`

**File**: `cw_core/lib/wallet_type.dart`

```dart
enum WalletType {
  // ... existing types ...
  @HiveField(19) // Next available field ID
  optimism,
}
```

A new `WalletType` touches every exhaustive `switch` over the enum, so expect the analyzer to point at many files. Follow the `WalletType.bsc` cases.

**File**: `lib/di.dart`

Add your wallet type to the `WalletService` factory:

```dart
factory WalletService(WalletType type, bool isDirect) {
  switch (type) {
    // ... existing cases ...
    case WalletType.optimism:
      return evm!.createEVMWalletService(type, isDirect);
  }
}
```

**Note**: The unified `evm` proxy handles the new type, so no proxy file is needed, only the new `case`.

#### Promoting an added network to built-in

Users may already have the chain as an added network. To make it built-in later, add it as a built-in chain with the steps in this guide, and keep its chain ID out of the add list: the Add EVM networks page (`manage_evm_networks_bloc.dart`) drops any chain the registry reports as built-in, and the chain should also leave `assets/evm_networks/popular.json`. Existing users still have an `EvmNetwork` row and `WalletType.evm` wallets with that chain ID, and `registerAddedNetworkCurrency` throws for a built-in chain ID, so the promotion also needs a migration that moves those rows and wallets to the new type.

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
✅ **Wallet creation** - Users can create wallets of your chain's `WalletType` from the Wallet Network picker  
✅ **Chain switching** - Users can switch between chains seamlessly  
✅ **All operations** - Balance fetching, transaction sending, etc. all work  
✅ **Transaction filtering** - Transactions are automatically filtered by `chainId`  
✅ **Node connection** - Automatic node connection when switching chains (uses `chainId` to find correct nodes)  
✅ **Balance updates** - Automatic balance refresh when switching chains  
✅ **ERC20 tokens** - Default tokens are automatically loaded  
✅ **Transaction history** - Separate history files per chain  
✅ **Backward compatibility** - Old wallet types continue to work

## Testing Checklist

- [ ] Create a new wallet of the chain's `WalletType`
- [ ] Check the chain no longer shows in the Add EVM networks list
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
- For a built-in chain, nodes come from its YAML list through `settingsStore.getCurrentNode(walletType, chainId: chainId)`. Only added networks (`WalletType.evm`) are looked up by `chainId` alone, in `settingsStore.evmChainNodes`
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
6. **Add the WalletType and DI registration** (Step 7) - Required

### For Chains with Custom Behavior

- Add **Step 5** (Custom Client) only if needed
- Add **Step 8** (Box Name Constant) only if custom box name needed

### Key Points

✅ **One `WalletType` per built-in chain** - `WalletType.evm` is only for networks users add at runtime  
✅ **Everything is `chainId`-based** - All operations use `chainId`, not `walletType`  
✅ **Registry-driven** - Chain configuration is centralized in `EvmChainRegistry`  
✅ **Backward compatible** - Old wallet types (ethereum, polygon, base, arbitrum) still work  
✅ **No proxy files needed** - The unified `evm` proxy handles all chains  
✅ **Automatic chain switching** - Users can switch chains without creating new wallets  

### What You DON'T Need to Do

❌ Create a new proxy file (unified proxy handles all chains)  
❌ Create a new wallet service (unified service handles all chains)  
❌ Create a new wallet class (unified `EVMChainWallet` handles all chains)  
❌ Update view models (they work with any EVM chain via proxy)  
❌ Update UI components (chain switcher auto-populates from registry)  

**Key Point**: With the unified EVM architecture, adding new L2 chains is now much simpler - most chains only require Registry configuration and default tokens!
