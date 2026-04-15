import 'package:cw_core/erc20_token.dart';

/// USDT0 (Omnichain USDT) config. 
/// Addresses and EIDs from https://docs.usdt0.to/technical-documentation/developer/usdt0-deployments
class USDT0Config {
  USDT0Config._();

  static const String ethereumOftAdapter =
      '0x6C96dE32CEa08842dcc4058c14d3aaAD7Fa41dee';

  static const String ethereumNativeUsdt =
      '0xdac17f958d2ee523a2206206994597c13d831ec7';

  static const Map<int, String> usdt0TokenAddressByChainId = {
    1: ethereumNativeUsdt,
    137: '0xc2132D05D31c914a87C6611C10748AEb04B58e8F',
    42161: '0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9',
  };

  static const Map<int, String> oftContractAddressByChainId = {
    1: ethereumOftAdapter,
    137: '0x6BA10300f0DC58B7a1e4c0e41f5daBb7D7829e13',
    42161: '0x14E4A1B13bf7F943c8ff7C51fb60FA964A298D92',
  };

  static const Map<int, int> endpointIdByChainId = {
    1: 30101,
    137: 30109,
    42161: 30110,
  };

  static const int ethereumChainId = 1;

  static List<int> get supportedChainIds =>
      usdt0TokenAddressByChainId.keys.toList(growable: false);

  static String? getOftAdapterAddress(int chainId) {
    if (chainId == ethereumChainId) return ethereumOftAdapter;
    return null;
  }

  static String? getUsdt0TokenAddress(int chainId) =>
      usdt0TokenAddressByChainId[chainId];

  static String? getOftContractAddress(int chainId) =>
      oftContractAddressByChainId[chainId];

  static int? getEndpointId(int chainId) => endpointIdByChainId[chainId];

  static bool isChainSupported(int chainId) =>
      usdt0TokenAddressByChainId.containsKey(chainId);

  static bool isUSDT0Token(Erc20Token token, int chainId) {
    final address = getUsdt0TokenAddress(chainId);
    if (address == null) return false;
    return token.contractAddress.toLowerCase() == address.toLowerCase();
  }
}
