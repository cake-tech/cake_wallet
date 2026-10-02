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
  final Map<String, int> _tagToChainId = {};
  final Map<int, EvmNetwork> _addedNetworks = {};

  bool _initialized = false;

  /// Initialize registry with all supported EVM chains
  void initialize() {
    if (_initialized) return;
    _initialized = true;

    // Ethereum Mainnet
    _registerBuiltinChain(
      const ChainConfig(
        chainId: 1,
        name: 'Ethereum',
        shortCode: 'eth',
        caip2: 'eip155:1',
        nativeCurrency: CryptoCurrency.eth,
        explorerUrls: [
          'https://etherscan.io',
        ],
        feeModel: FeeModel(type: FeeType.eip1559),
      ),
      WalletType.ethereum,
      'ETH',
    );

    // Polygon
    _registerBuiltinChain(
      const ChainConfig(
        chainId: 137,
        name: 'Polygon',
        shortCode: 'polygon',
        caip2: 'eip155:137',
        nativeCurrency: CryptoCurrency.maticpoly,
        explorerUrls: [
          'https://polygonscan.com',
        ],
        feeModel: FeeModel(type: FeeType.legacy),
      ),
      WalletType.polygon,
      'POL',
    );

    // Base
    _registerBuiltinChain(
      const ChainConfig(
        chainId: 8453,
        name: 'Base',
        shortCode: 'base',
        caip2: 'eip155:8453',
        nativeCurrency: CryptoCurrency.baseEth,
        explorerUrls: [
          'https://basescan.org',
        ],
        feeModel: FeeModel(type: FeeType.legacy),
      ),
      WalletType.base,
      'BASE',
    );

    // Arbitrum
    _registerBuiltinChain(
      const ChainConfig(
        chainId: 42161,
        name: 'Arbitrum',
        shortCode: 'arbitrum',
        caip2: 'eip155:42161',
        nativeCurrency: CryptoCurrency.arbEth,
        explorerUrls: [
          'https://arbiscan.io',
        ],
        feeModel: FeeModel(type: FeeType.legacy),
      ),
      WalletType.arbitrum,
      'ARB',
    );

    // BNB Smart Chain
    _registerBuiltinChain(
      const ChainConfig(
        chainId: 56,
        name: 'BNB Smart Chain',
        shortCode: 'bsc',
        caip2: 'eip155:56',
        nativeCurrency: CryptoCurrency.bnb,
        explorerUrls: [
          'https://bscscan.com',
        ],
        feeModel: FeeModel(type: FeeType.legacy),
      ),
      WalletType.bsc,
      'BSC',
    );
  }

  void _registerBuiltinChain(
    ChainConfig config,
    WalletType walletType,
    String tag,
  ) {
    _chains[config.chainId] = config;
    _walletTypeToChainId[walletType] = config.chainId;
    _tagToChainId[tag.toUpperCase()] = config.chainId;
  }

  bool isBuiltinChain(int chainId) => _walletTypeToChainId.containsValue(chainId);

  void _throwIfBuiltinChain(int chainId) {
    if (isBuiltinChain(chainId)) {
      throw ArgumentError.value(chainId, "chainId", "Chain ID is a built-in network");
    }
  }

  void registerAddedNetwork(EvmNetwork network) {
    _throwIfBuiltinChain(network.chainId);

    final currency = _registerCurrency(network);
    if (!network.isEnabled) {
      _removeChain(network.chainId);
      return;
    }

    final explorerUrl = network.explorerUrl;
    _chains[network.chainId] = ChainConfig(
      chainId: network.chainId,
      name: network.name,
      shortCode: "evm${network.chainId}",
      caip2: "eip155:${network.chainId}",
      nativeCurrency: currency,
      explorerUrls: [
        if (explorerUrl != null && explorerUrl.isNotEmpty) explorerUrl,
      ],
      feeModel: const FeeModel(type: FeeType.eip1559OrLegacy),
    );
    _addedNetworks[network.chainId] = network;
  }

  void unregisterAddedNetwork(int chainId) {
    _throwIfBuiltinChain(chainId);

    _removeChain(chainId);
    EvmNativeCurrencies.unregister(chainId);
  }

  void unregisterAllAddedNetworks() {
    for (final chainId in EvmNativeCurrencies.addedNetworkChainIds.toList()) {
      unregisterAddedNetwork(chainId);
    }
  }

  AddedNetworkCurrency _registerCurrency(EvmNetwork network) {
    final registered = EvmNativeCurrencies.getNativeCurrencyByChainId(network.chainId);
    final currency =
        registered is AddedNetworkCurrency ? registered : AddedNetworkCurrency(network);
    currency.network = network;

    EvmNativeCurrencies.register(network.chainId, currency, WalletType.evm);
    return currency;
  }

  void _removeChain(int chainId) {
    _chains.remove(chainId);
    _addedNetworks.remove(chainId);
  }

  EvmNetwork? getAddedNetwork(int chainId) => _addedNetworks[chainId];

  ChainConfig? getChainConfig(int chainId) => _chains[chainId];

  /// Get chain configuration by tag (e.g., 'ETH', 'POL', 'BASE', 'ARB')
  ChainConfig? getChainConfigByTag(String tag) {
    final chainId = _tagToChainId[tag.toUpperCase()];
    return chainId != null ? _chains[chainId] : null;
  }

  WalletType? getWalletTypeByChainId(int chainId) =>
      isChainRegistered(chainId) ? EvmNativeCurrencies.getWalletTypeByChainId(chainId) : null;

  int? getChainIdByWalletType(WalletType walletType) => _walletTypeToChainId[walletType];

  int? getWalletChainId(WalletInfo walletInfo) => walletInfo.type == WalletType.evm
      ? walletInfo.chainId
      : getChainIdByWalletType(walletInfo.type);

  bool isChainRegistered(int chainId) => _chains.containsKey(chainId);

  List<ChainConfig> getAllChains() => _chains.values.toList();

  List<WalletType> getRegisteredWalletTypes() => [..._walletTypeToChainId.keys, WalletType.evm];
}
