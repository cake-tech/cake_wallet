import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/wallet_type.dart';

CryptoCurrency walletTypeToCryptoCurrency(WalletType type, {bool isTestnet = false}) {
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
