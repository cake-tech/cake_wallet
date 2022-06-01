import 'package:cw_core/crypto_currency.dart';

class CurrencyUtils {
  static String tagForCurrency(CryptoCurrency cur) {
    switch (cur) {
      case CryptoCurrency.bnb:
        return 'BEP2';
      case CryptoCurrency.dai:
        return 'ETH';
      case CryptoCurrency.usdt:
        return 'OMNI';
      case CryptoCurrency.usdterc20:
        return 'ETH';
      default:
        return null;
    }
  }

  static String iconPathForCurrency(CryptoCurrency cur) {
    switch (cur) {
      case CryptoCurrency.xmr:
        return 'assets/images/monero_icon.png';
      case CryptoCurrency.ada:
        return 'assets/images/ada_icon.png';
      case CryptoCurrency.bch:
        return 'assets/images/bch_icon.png';
      case CryptoCurrency.bnb:
        return 'assets/images/bnb_icon.png';
      case CryptoCurrency.btc:
        return 'assets/images/btc.png';
      case CryptoCurrency.dai:
        return 'assets/images/dai_icon.png';
      case CryptoCurrency.dash:
        return 'assets/images/dash_icon.png';
      case CryptoCurrency.eos:
        return 'assets/images/eos_icon.png';
      case CryptoCurrency.eth:
        return 'assets/images/eth_icon.png';
      case CryptoCurrency.ltc:
        return 'assets/images/litecoin-ltc_icon.png';
      case CryptoCurrency.trx:
        return 'assets/images/trx_icon.png';
      case CryptoCurrency.usdt:
        return 'assets/images/usdt_icon.png';
      case CryptoCurrency.usdterc20:
        return 'assets/images/usdterc20_icon.png';
      case CryptoCurrency.xlm:
        return 'assets/images/xlm_icon.png';
      case CryptoCurrency.xrp:
        return 'assets/images/xrp_icon.png';
      case CryptoCurrency.xhv:
        return 'assets/images/xhv_logo.png';
      default:
        return null;
    }
  }

  static String titleForCurrency(CryptoCurrency cur) {
    switch (cur) {
      case CryptoCurrency.bnb:
        return 'BNB';
      case CryptoCurrency.usdterc20:
        return 'USDT';
      default:
        return cur.title;
    }
  }

  static String descriptionForCurrency(CryptoCurrency cur) {
    switch (cur) {
      case CryptoCurrency.xmr:
        return 'monero';
      case CryptoCurrency.ada:
        return 'cardano';
      case CryptoCurrency.bch:
        return 'bitcoin cash';
      case CryptoCurrency.bnb:
        return 'binance bep2';
      case CryptoCurrency.btc:
        return 'bitcoin';
      case CryptoCurrency.dai:
        return 'dai eth';
      case CryptoCurrency.eth:
        return 'ethereum';
      case CryptoCurrency.ltc:
        return 'litecoin';
      case CryptoCurrency.trx:
        return 'tron';
      case CryptoCurrency.usdt:
        return 'usdt omni';
      case CryptoCurrency.usdterc20:
        return 'tether ERC20 eth';
      case CryptoCurrency.xlm:
        return 'lumens';
      case CryptoCurrency.xrp:
        return 'ripple';
      default:
        return cur.title;
    }
  }
}
