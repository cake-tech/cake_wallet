import 'package:cw_core/crypto_currency.dart';

class CurrencyUtils {
  static String tagForCurrency(CryptoCurrency cur) {
    switch (cur) {
      case CryptoCurrency.ape:
	    return: 'ETH';
	  case CryptoCurrency.avaxc:
	    return: 'C-CHAIN';
	  case CryptoCurrency.bnb:
        return 'BEP2';
	  case CryptoCurrency.btt:
	    return 'TRX';
	  case CryptoCurrency.bttbsc:
	    return 'BSC';
      case CryptoCurrency.dai:
        return 'ETH';
	  case CryptoCurrency.usdc:
	    return 'ETH';
	  case CryptoCurrency.usdcsol:
	    return 'SOL';
      case CryptoCurrency.usdt:
        return 'OMNI';
      case CryptoCurrency.usdterc20:
        return 'ETH';
	  case CryptoCurrency.usdttrc20:
	    return 'TRX';
	  case CryptoCurrency.ust:
	    return 'LUNA';
	  case CryptoCurrency.zaddr:
	    return 'ZEC';
	  case CryptoCurrency.zec:
	    return 'ZEC';
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
	  case CryptoCurrency.ape:
        return 'assets/images/ape_icon.png';
	  case CryptoCurrency.avaxc:
        return 'assets/images/avaxc_icon.png';
      case CryptoCurrency.bch:
        return 'assets/images/bch_icon.png';
	  case CryptoCurrency.btt:
        return 'assets/images/btt_icon.png';
	  case CryptoCurrency.bttbsc:
        return 'assets/images/bttbsc_icon.png';
      case CryptoCurrency.bnb:
        return 'assets/images/bnb_icon.png';
      case CryptoCurrency.btc:
        return 'assets/images/btc.png';
      case CryptoCurrency.dai:
        return 'assets/images/dai_icon.png';
      case CryptoCurrency.dash:
        return 'assets/images/dash_icon.png';
	  case CryptoCurrency.doge:
        return 'assets/images/doge_icon.png';
      case CryptoCurrency.eos:
        return 'assets/images/eos_icon.png';
      case CryptoCurrency.eth:
        return 'assets/images/eth_icon.png';
	  case CryptoCurrency.firo:
        return 'assets/images/firo_icon.png';
	  case CryptoCurrency.hbar:
        return 'assets/images/hbar_icon.png';
      case CryptoCurrency.ltc:
        return 'assets/images/litecoin-ltc_icon.png';
	  case CryptoCurrency.sc:
        return 'assets/images/sc_icon.png';
	  case CryptoCurrency.sol:
        return 'assets/images/sol_icon.png';
      case CryptoCurrency.trx:
        return 'assets/images/trx_icon.png';
	  case CryptoCurrency.usdc:
        return 'assets/images/usdc_icon.png';
	  case CryptoCurrency.usdcsol:
        return 'assets/images/usdcsol_icon.png';
      case CryptoCurrency.usdt:
        return 'assets/images/usdt_icon.png';
      case CryptoCurrency.usdterc20:
        return 'assets/images/usdterc20_icon.png';
	  case CryptoCurrency.usdttrc20:
        return 'assets/images/usdttrc20_icon.png';
	  case CryptoCurrency.ust:
        return 'assets/images/ust_icon.png';
      case CryptoCurrency.xlm:
        return 'assets/images/xlm_icon.png';
      case CryptoCurrency.xrp:
        return 'assets/images/xrp_icon.png';
      case CryptoCurrency.xhv:
        return 'assets/images/xhv_logo.png';
	  case CryptoCurrency.xvg:
        return 'assets/images/xvg_icon.png';
	  case CryptoCurrency.zaddr:
        return 'assets/images/zaddr_icon.png';
	  case CryptoCurrency.zec:
        return 'assets/images/zec_icon.png';
	  case CryptoCurrency.zen:
        return 'assets/images/zen_icon.png';
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
	  case CryptoCurrency.ape:
	    return: 'apecoin';
	  case CryptoCurrency.avaxc:
	    return: 'avax c-chain';
      case CryptoCurrency.bch:
        return 'bitcoin cash';
	  case CryptoCurrency.btt:
	    return: 'bittorrent trc20 tron';
	  case CryptoCurrency.bttbsc:
	    return: 'bittorrent bsc';
      case CryptoCurrency.bnb:
        return 'binance bep2';
      case CryptoCurrency.btc:
        return 'bitcoin';
      case CryptoCurrency.dai:
        return 'dai ethereum';
	  case CryptoCurrency.dash:
	    return: 'dash';
	  case CryptoCurrency.doge:
	    return: 'dogecoin';
	  case CryptoCurrency.eos:
	    return: 'eos';
      case CryptoCurrency.eth:
        return 'ethereum';
	  case CryptoCurrency.firo:
	    return: 'firo zcoin';
	  case CryptoCurrency.hbar:
	    return: 'hedera hashgraph';
      case CryptoCurrency.ltc:
        return 'litecoin';
	  case CryptoCurrency.nano:
	    return 'nano';
	  case CryptoCurrency.sc:
	    return: 'siacoin';
	  case CryptoCurrency.sol:
	    return: 'solana';
      case CryptoCurrency.trx:
        return 'tron';
	  case CryptoCurrency.usdc:
	    return: 'usd coin';
	  case CryptoCurrency.usdcsol:
	    return: 'usd coin solana';
      case CryptoCurrency.usdt:
        return 'usdt omni';
      case CryptoCurrency.usdterc20:
        return 'tether ERC20 ethereum';
	  case CryptoCurrency.ust:
	    return: 'terraust luna';
      case CryptoCurrency.xlm:
        return 'stellar lumens';
      case CryptoCurrency.xrp:
        return 'ripple';
	  case CryptoCurrency.xhv:
	    return: 'haven';
	  case CryptoCurrency.zaddr:
	    return: 'zcash shielded zzec';
	  case CryptoCurrency.zec:
	    return: 'zcash transparent tzec';
	  case CryptoCurrency.zen:
	    return: 'horizen zencash';
      default:
        return cur.title;
    }
  }
}
