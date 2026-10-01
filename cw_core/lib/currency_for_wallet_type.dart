import "package:collection/collection.dart";
import 'package:cw_core/crypto_currency.dart';
import "package:cw_core/erc20_token.dart";
import "package:cw_core/wallet_info.dart";
import 'package:cw_core/wallet_type.dart';

class _EvmNative {
  const _EvmNative({
    required this.currency,
    required this.walletType,
  });

  final CryptoCurrency currency;
  final WalletType walletType;
}

class EvmNativeCurrencies {
  // Any currency raw above this number is automatically an addedNetwork, and it contains the offset and chainId
  static const int addedNetworkRawOffset = 1000000000000;

  static final Map<int, _EvmNative> _natives = {
    1: const _EvmNative(currency: CryptoCurrency.eth, walletType: WalletType.ethereum),
    137: const _EvmNative(currency: CryptoCurrency.maticpoly, walletType: WalletType.polygon),
    8453: const _EvmNative(currency: CryptoCurrency.baseEth, walletType: WalletType.base),
    42161: const _EvmNative(currency: CryptoCurrency.arbEth, walletType: WalletType.arbitrum),
    56: const _EvmNative(currency: CryptoCurrency.bnb, walletType: WalletType.bsc),
  };

  static void register(int chainId, CryptoCurrency currency, WalletType walletType) =>
      _natives[chainId] = _EvmNative(currency: currency, walletType: walletType);

  static void unregister(int chainId) => _natives.remove(chainId);

  static CryptoCurrency? getNativeCurrencyByChainId(int chainId) => _natives[chainId]?.currency;

  static WalletType? getWalletTypeByChainId(int chainId) => _natives[chainId]?.walletType;

  static int addedNetworkRaw(int chainId) => addedNetworkRawOffset + chainId;

  static int? getAddedNetworkChainId(CryptoCurrency currency) {
    final chainId = getChainIdByCryptoCurrency(currency);
    if (chainId == null) {
      return null;
    }

    final walletType = getWalletTypeByChainId(chainId);
    return walletType == null || walletType == WalletType.evm ? chainId : null;
  }

  static bool isAddedNetworkCurrency(CryptoCurrency currency) =>
      getAddedNetworkChainId(currency) != null;

  static bool isWalletForCurrency(WalletInfo info, CryptoCurrency currency) {
    if (cryptoCurrencyOrTokenToWalletType(currency) != info.type) {
      return false;
    }

    if (info.type != WalletType.evm) {
      return true;
    }

    return info.chainId != null && info.chainId == getChainIdByCryptoCurrency(currency);
  }
}

CryptoCurrency walletTypeToCryptoCurrency(WalletType type, {bool isTestnet = false, int? chainId}) {
  if (chainId != null) {
    return getCryptoCurrencyByChainId(chainId);
  }

  switch (type) {
    case WalletType.monero:
      return CryptoCurrency.xmr;
    case WalletType.bitcoin:
      if (isTestnet) {
        return CryptoCurrency.tbtc;
      }
      return CryptoCurrency.btc;
    case WalletType.litecoin:
      return CryptoCurrency.ltc;
    case WalletType.haven:
      return CryptoCurrency.xhv;
    case WalletType.ethereum:
      return CryptoCurrency.eth;
    case WalletType.base:
      return CryptoCurrency.baseEth;
    case WalletType.arbitrum:
      return CryptoCurrency.arbEth;
    case WalletType.bsc:
      return CryptoCurrency.bnb;
    case WalletType.bitcoinCash:
      return CryptoCurrency.bch;
    case WalletType.nano:
      return CryptoCurrency.nano;
    case WalletType.banano:
      return CryptoCurrency.banano;
    case WalletType.polygon:
      return CryptoCurrency.maticpoly;
    case WalletType.solana:
      return CryptoCurrency.sol;
    case WalletType.tron:
      return CryptoCurrency.trx;
    case WalletType.wownero:
      return CryptoCurrency.wow;
    case WalletType.zano:
      return CryptoCurrency.zano;
    case WalletType.decred:
      return CryptoCurrency.dcr;
    case WalletType.dogecoin:
      return CryptoCurrency.doge;
    case WalletType.zcash:
      return CryptoCurrency.zec;
    case WalletType.evm:
      throw Exception("An EVM wallet's currency needs its chain ID");
    case WalletType.none:
      throw Exception(
          'Unexpected wallet type: ${type.toString()} for CryptoCurrency walletTypeToCryptoCurrency');
  }
}

CryptoCurrency getCryptoCurrencyByChainId(int chainId) {
  final currency = EvmNativeCurrencies.getNativeCurrencyByChainId(chainId);
  if (currency == null) {
    throw Exception("No EVM network registered for chain ID $chainId");
  }

  return currency;
}

/// Get chainId from CryptoCurrency for EVM chains
/// Returns null if currency is not an EVM chain
int? getChainIdByCryptoCurrency(CryptoCurrency currency) {
  if (currency is Erc20Token) {
    return currency.chainId;
  }

  if (currency.raw >= EvmNativeCurrencies.addedNetworkRawOffset) {
    final addedNetworkChainId = currency.raw - EvmNativeCurrencies.addedNetworkRawOffset;
    return addedNetworkChainId;
  }

  return EvmNativeCurrencies._natives.entries
      .firstWhereOrNull((entry) => entry.value.currency == currency)
      ?.key;
}

CryptoCurrency getCryptoCurrencyForWalletListItem(WalletType type,
    {bool isTestnet = false, int? chainId}) {
  if (type == WalletType.arbitrum) {
    return CryptoCurrency.arb;
  }

  return walletTypeToCryptoCurrency(type, isTestnet: isTestnet, chainId: chainId);
}

String getCryptoCurrencyIconForWalletListItem(WalletType type,
    {bool isTestnet = false, int? chainId}) {
  if (type == WalletType.arbitrum) {
    return CryptoCurrency.arb.iconPath!;
  }

  if (type == WalletType.base) {
    return "assets/new-ui/crypto_full_icons/base.svg";
  }

  return walletTypeToCryptoCurrency(type, isTestnet: isTestnet, chainId: chainId).iconPath ?? "";
}

String? symbolIconPathForWalletType(WalletType type) {
  const prefix = "assets/new-ui/card_icons/symbol_icons";
  switch (type) {
    case WalletType.monero:
      return "$prefix/xmr-symbol.svg";
    case WalletType.bitcoin:
      return "$prefix/btc-symbol.svg";
    case WalletType.litecoin:
      return "$prefix/ltc-symbol.svg";
    case WalletType.ethereum:
      return "$prefix/eth-symbol.svg";
    case WalletType.base:
      return "$prefix/base-symbol.svg";
    case WalletType.arbitrum:
      return "$prefix/arb-symbol.svg";
    case WalletType.bsc:
      return "$prefix/bnb-symbol.svg";
    case WalletType.bitcoinCash:
      return "$prefix/bch-symbol.svg";
    case WalletType.polygon:
      return "$prefix/pol-symbol.svg";
    case WalletType.solana:
      return "$prefix/sol-symbol.svg";
    case WalletType.tron:
      return "$prefix/trx-symbol.svg";
    case WalletType.zano:
      return "$prefix/zano-symbol.svg";
    case WalletType.decred:
      return "$prefix/dcr-symbol.svg";
    case WalletType.dogecoin:
      return "$prefix/doge-symbol.svg";
    case WalletType.zcash:
      return "$prefix/zec-symbol.svg";
    case WalletType.nano:
      return "$prefix/xno-symbol.svg";
    case WalletType.wownero:
    case WalletType.haven:
    case WalletType.banano:
    case WalletType.evm:
    case WalletType.none:
      return null;
  }
}

bool isMonochromeSymbolIcon(String path) => path.contains("/symbol_icons/");
