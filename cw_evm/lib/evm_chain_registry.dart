import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_evm/chain_config.dart';

/// Centralized registry for all EVM chain configurations
class EvmChainRegistry {
  static final EvmChainRegistry _instance = EvmChainRegistry._internal();
  factory EvmChainRegistry() => _instance;
  EvmChainRegistry._internal();

  final Map<int, ChainConfig> _chains = {};
  final Map<WalletType, int> _walletTypeToChainId = {};
  final Map<int, WalletType> _chainIdToWalletType = {};
  final Map<String, int> _tagToChainId = {};
  final Map<String, int> _caip2ToChainId = {};

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
        defaultRpcEndpoints: [
          'ethereum-rpc.publicnode.com',
          'eth.llamarpc.com',
          'rpc.flashbots.net',
          'eth-mainnet.public.blastapi.io',
          'eth.nownodes.io',
          'ethereum.publicnode.com',
        ],
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
        defaultRpcEndpoints: [
          'polygon-rpc.com',
          'polygon-bor-rpc.publicnode.com',
          'polygon.llamarpc.com',
          'matic.nownodes.io',
        ],
        explorerUrls: [
          'https://polygonscan.com',
        ],
        feeModel: FeeModel(
          type: FeeType.eip1559,
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
        defaultRpcEndpoints: [
          'base.nownodes.io',
          'base.llamarpc.com',
          'base-rpc.publicnode.com',
          '1rpc.io/base',
        ],
        explorerUrls: [
          'https://basescan.org',
        ],
        feeModel: FeeModel(
          type: FeeType.eip1559,
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
        defaultRpcEndpoints: [
          'arbitrum.nownodes.io',
          'arbitrum.drpc.org',
          'arbitrum-one-rpc.publicnode.com',
        ],
        explorerUrls: [
          'https://arbiscan.io',
        ],
        feeModel: FeeModel(
          type: FeeType.eip1559,
          defaultGasLimit: 21000,
        ),
      ),
      WalletType.arbitrum,
      'ARB',
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
  }

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

  /// Get all available chain configurations for a given WalletType
  /// For EVM wallets, returns all registered EVM chains since they can switch between chains
  List<ChainConfig> getAvailableChainsForWallet(WalletType walletType) {
    // If it's an EVM wallet type, return all EVM chains (all EVM wallets can use all EVM chains)
    if (_walletTypeToChainId.containsKey(walletType)) {
      return _chains.values.toList();
    }
    return [];
  }

  WalletType? getWalletTypeByChainId(int chainId) => _chainIdToWalletType[chainId];

  int? getChainIdByWalletType(WalletType walletType) => _walletTypeToChainId[walletType];

  bool isChainRegistered(int chainId) => _chains.containsKey(chainId);

  List<int> getRegisteredChainIds() => _chains.keys.toList();

  List<ChainConfig> getAllChains() => _chains.values.toList();
}
