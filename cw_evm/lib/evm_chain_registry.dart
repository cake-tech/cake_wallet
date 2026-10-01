import 'package:cw_core/crypto_currency.dart';
import "package:cw_core/currency_for_wallet_type.dart";
import "package:cw_core/evm_network.dart";
import "package:cw_core/wallet_info.dart";
import 'package:cw_core/wallet_type.dart';
import 'package:cw_evm/utils/network_chain_utils.dart';

/// Centralized registry for all EVM chain configurations
class EvmChainRegistry {
  static final EvmChainRegistry _instance = EvmChainRegistry._internal();
  factory EvmChainRegistry() => _instance;
  EvmChainRegistry._internal() {
    initialize();
  }

  final Map<int, ChainConfig> _chains = {};
  final Map<WalletType, int> _walletTypeToChainId = {};
  final Map<int, WalletType> _chainIdToWalletType = {};
  final Map<String, int> _tagToChainId = {};
  final Map<String, int> _caip2ToChainId = {};
  final Map<int, EvmNetwork> _addedNetworks = {};
  final Map<int, AddedNetworkCurrency> _addedNetworkCurrencies = {};

  bool _initialized = false;

  /// Initialize registry with all supported EVM chains
  void initialize() {
    if (_initialized) return;
    _initialized = true;

    // Ethereum Mainnet
    _registerChain(
      const ChainConfig(
        chainId: 1,
        name: 'Ethereum',
        shortCode: 'eth',
        caip2: 'eip155:1',
        nativeCurrency: CryptoCurrency.eth,
        capabilities: ChainCapabilities(
          supportsERC20: true,
          supportsEIP1559: true,
          supportsInternalTx: true,
          supportsSubscriptions: false,
          supportsENS: true,
        ),
        explorerUrls: [
          'https://etherscan.io',
        ],
        feeModel: FeeModel(
          type: FeeType.eip1559,
          defaultGasLimit: 21000,
        ),
      ),
      WalletType.ethereum,
      'ETH',
    );

    // Polygon
    _registerChain(
      const ChainConfig(
        chainId: 137,
        name: 'Polygon',
        shortCode: 'polygon',
        caip2: 'eip155:137',
        nativeCurrency: CryptoCurrency.maticpoly,
        capabilities: ChainCapabilities(
          supportsERC20: true,
          supportsEIP1559: true,
          supportsInternalTx: true,
          supportsSubscriptions: false,
          supportsENS: false,
        ),
        explorerUrls: [
          'https://polygonscan.com',
        ],
        feeModel: FeeModel(
          type: FeeType.legacy,
          defaultGasLimit: 21000,
        ),
      ),
      WalletType.polygon,
      'POL',
    );

    // Base
    _registerChain(
      const ChainConfig(
        chainId: 8453,
        name: 'Base',
        shortCode: 'base',
        caip2: 'eip155:8453',
        nativeCurrency: CryptoCurrency.baseEth,
        capabilities: ChainCapabilities(
          supportsERC20: true,
          supportsEIP1559: true,
          supportsInternalTx: true,
          supportsSubscriptions: false,
          supportsENS: false,
        ),
        explorerUrls: [
          'https://basescan.org',
        ],
        feeModel: FeeModel(
          type: FeeType.legacy,
          defaultGasLimit: 21000,
        ),
      ),
      WalletType.base,
      'BASE',
    );

    // Arbitrum
    _registerChain(
      const ChainConfig(
        chainId: 42161,
        name: 'Arbitrum',
        shortCode: 'arbitrum',
        caip2: 'eip155:42161',
        nativeCurrency: CryptoCurrency.arbEth,
        capabilities: ChainCapabilities(
          supportsERC20: true,
          supportsEIP1559: true,
          supportsInternalTx: true,
          supportsSubscriptions: false,
          supportsENS: false,
        ),
        explorerUrls: [
          'https://arbiscan.io',
        ],
        feeModel: FeeModel(
          type: FeeType.legacy,
          defaultGasLimit: 21000,
        ),
      ),
      WalletType.arbitrum,
      'ARB',
    );

    // BNB Smart Chain
    _registerChain(
      const ChainConfig(
        chainId: 56,
        name: 'BNB Smart Chain',
        shortCode: 'bsc',
        caip2: 'eip155:56',
        nativeCurrency: CryptoCurrency.bnb,
        capabilities: ChainCapabilities(
          supportsERC20: true,
          supportsEIP1559: true,
          supportsInternalTx: true,
          supportsSubscriptions: false,
          supportsENS: false,
        ),
        explorerUrls: [
          'https://bscscan.com',
        ],
        feeModel: FeeModel(
          type: FeeType.legacy,
          defaultGasLimit: 21000,
        ),
      ),
      WalletType.bsc,
      'BSC',
    );
  }

  void _registerChain(
    ChainConfig config,
    WalletType walletType,
    String tag,
  ) {
    _chains[config.chainId] = config;
    _walletTypeToChainId[walletType] = config.chainId;
    _chainIdToWalletType[config.chainId] = walletType;
    _tagToChainId[tag.toUpperCase()] = config.chainId;
    _caip2ToChainId[config.caip2] = config.chainId;
    EvmNativeCurrencies.register(config.chainId, config.nativeCurrency, walletType);
  }

  bool isBuiltinChain(int chainId) => _walletTypeToChainId.containsValue(chainId);

  void _throwIfBuiltinChain(int chainId) {
    if (isBuiltinChain(chainId)) {
      throw ArgumentError.value(chainId, "chainId", "Chain ID is a built-in network");
    }
  }

  CryptoCurrency registerAddedNetworkCurrency(EvmNetwork network) {
    _throwIfBuiltinChain(network.chainId);

    final currency = _addedNetworkCurrencies[network.chainId] ??= AddedNetworkCurrency(network);
    currency
      ..networkName = network.name
      ..iconUrl = network.iconUrl
      ..isManual = network.isManual;

    EvmNativeCurrencies.register(network.chainId, currency, WalletType.evm);
    return currency;
  }

  void registerAddedNetworkChain(EvmNetwork network) {
    final currency = registerAddedNetworkCurrency(network);
    final explorerUrl = network.explorerUrl;

    final config = ChainConfig(
      chainId: network.chainId,
      name: network.name,
      shortCode: "evm${network.chainId}",
      caip2: "eip155:${network.chainId}",
      nativeCurrency: currency,
      capabilities: const ChainCapabilities(
        supportsERC20: true,
        supportsEIP1559: true,
        supportsInternalTx: true,
        supportsSubscriptions: false,
        supportsENS: false,
      ),
      explorerUrls: [
        if (explorerUrl != null && explorerUrl.isNotEmpty) explorerUrl,
      ],
      feeModel: const FeeModel(
        type: FeeType.eip1559OrLegacy,
        defaultGasLimit: 21000,
      ),
    );

    _chains[config.chainId] = config;
    _chainIdToWalletType[config.chainId] = WalletType.evm;
    _caip2ToChainId[config.caip2] = config.chainId;
    _addedNetworks[config.chainId] = network;
  }

  void unregisterAddedNetworkChain(int chainId) {
    _throwIfBuiltinChain(chainId);

    final config = _chains.remove(chainId);
    _chainIdToWalletType.remove(chainId);
    _addedNetworks.remove(chainId);
    if (config != null) {
      _caip2ToChainId.remove(config.caip2);
    }
  }

  void unregisterAddedNetworkCurrency(int chainId) {
    _throwIfBuiltinChain(chainId);

    _addedNetworkCurrencies.remove(chainId);
    EvmNativeCurrencies.unregister(chainId);
  }

  void unregisterAllAddedNetworks() {
    for (final chainId in _addedNetworkCurrencies.keys.toList()) {
      unregisterAddedNetworkChain(chainId);
      unregisterAddedNetworkCurrency(chainId);
    }
  }

  EvmNetwork? getAddedNetwork(int chainId) => _addedNetworks[chainId];

  ChainConfig? getChainConfig(int chainId) => _chains[chainId];

  ChainConfig? getChainConfigByWalletType(WalletType walletType) {
    final chainId = _walletTypeToChainId[walletType];
    return chainId != null ? _chains[chainId] : null;
  }

  /// Get chain configuration by tag (e.g., 'ETH', 'POL', 'BASE', 'ARB')
  ChainConfig? getChainConfigByTag(String tag) {
    final chainId = _tagToChainId[tag.toUpperCase()];
    return chainId != null ? _chains[chainId] : null;
  }

  /// Get chain configuration by CAIP-2 identifier (e.g. 'eip155:1')
  ChainConfig? getChainConfigByCaip2(String caip2) {
    final chainId = _caip2ToChainId[caip2];
    return chainId != null ? _chains[chainId] : null;
  }

  WalletType? getWalletTypeByChainId(int chainId) => _chainIdToWalletType[chainId];

  int? getChainIdByWalletType(WalletType walletType) => _walletTypeToChainId[walletType];

  int? getChainIdOfWallet(WalletInfo walletInfo) => walletInfo.type == WalletType.evm
      ? walletInfo.chainId
      : getChainIdByWalletType(walletInfo.type);

  bool isChainRegistered(int chainId) => _chains.containsKey(chainId);

  List<int> getRegisteredChainIds() => _chains.keys.toList();

  List<ChainConfig> getAllChains() => _chains.values.toList();

  List<WalletType> getRegisteredWalletTypes() => [..._walletTypeToChainId.keys, WalletType.evm];
}
