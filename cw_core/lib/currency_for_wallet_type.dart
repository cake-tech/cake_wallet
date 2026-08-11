import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/wallet_type.dart';

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
    case WalletType.none:
      throw Exception(
          'Unexpected wallet type: ${type.toString()} for CryptoCurrency walletTypeToCryptoCurrency');
  }
}

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
    case 56:
      return CryptoCurrency.bnb;
    default:
      return CryptoCurrency.eth;
  }
}

/// Get chainId from CryptoCurrency for EVM chains
/// Returns null if currency is not an EVM chain
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
    case CryptoCurrency.bnb:
      return 56;
    default:
      return null;
  }
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
    case WalletType.none:
      return null;
  }
}

bool isMonochromeSymbolIcon(String path) => path.contains("/symbol_icons/");
