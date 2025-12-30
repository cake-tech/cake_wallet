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
    case WalletType.evm:
      if (chainId == null) {
        throw Exception(
          'chainId required for WalletType.evm. Use wallet.currency instead of walletTypeToCryptoCurrency(wallet.type) for EVM wallets.',
        );
      }
      return getCryptoCurrencyByChainId(chainId);
    case WalletType.ethereum:
      return CryptoCurrency.eth;
    case WalletType.base:
      return CryptoCurrency.baseEth;
    case WalletType.arbitrum:
      return CryptoCurrency.arbEth;
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
    default:
      return null;
  }
}
