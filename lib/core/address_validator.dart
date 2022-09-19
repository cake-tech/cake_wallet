import 'package:flutter/foundation.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/core/validator.dart';
import 'package:cw_core/crypto_currency.dart';

class AddressValidator extends TextValidator {
  AddressValidator({@required CryptoCurrency type})
      : super(
            errorMessage: S.current.error_text_address,
            pattern: getPattern(type),
            length: getLength(type));

  static String getPattern(CryptoCurrency type) {
    switch (type) {
      case CryptoCurrency.xmr:
        return '^4[0-9a-zA-Z]{94}\$|^8[0-9a-zA-Z]{94}\$|^[0-9a-zA-Z]{106}\$';
      case CryptoCurrency.ada:
        return '^[0-9a-zA-Z]{59}\$|^[0-9a-zA-Z]{92}\$|^[0-9a-zA-Z]{104}\$'
            '|^[0-9a-zA-Z]{105}\$|^addr1[0-9a-zA-Z]{98}\$';
      case CryptoCurrency.ape:
        return '0x[0-9a-zA-Z]';
      case CryptoCurrency.avaxc:
        return '0x[0-9a-zA-Z]';
      case CryptoCurrency.bch:
        return '[0-9a-zA-Z]';
      case CryptoCurrency.bnb:
        return '[0-9a-zA-Z]';
      case CryptoCurrency.btc:
        return '^1[0-9a-zA-Z]{32}\$|^1[0-9a-zA-Z]{33}\$|^3[0-9a-zA-Z]{32}\$'
            '|^3[0-9a-zA-Z]{33}\$|^bc1[0-9a-zA-Z]{39}\$|^bc1[0-9a-zA-Z]{59}\$';
      case CryptoCurrency.dai:
        return '[0-9a-zA-Z]';
      case CryptoCurrency.dash:
        return '[0-9a-zA-Z]';
      case CryptoCurrency.eos:
        return '[0-9a-zA-Z]';
      case CryptoCurrency.eth:
        return '0x[0-9a-zA-Z]';
      case CryptoCurrency.ltc:
        return '[0-9a-zA-Z]';
      case CryptoCurrency.nano:
        return '[0-9a-zA-Z_]';
      case CryptoCurrency.trx:
        return '[0-9a-zA-Z]';
      case CryptoCurrency.usdc:
        return '0x[0-9a-zA-Z]';
      case CryptoCurrency.usdt:
        return '[0-9a-zA-Z]';
      case CryptoCurrency.usdterc20:
        return '[0-9a-zA-Z]';
      case CryptoCurrency.xlm:
        return '[0-9a-zA-Z]';
      case CryptoCurrency.xrp:
        return '^[0-9a-zA-Z]{34}\$|^X[0-9a-zA-Z]{46}\$';
      case CryptoCurrency.xhv:
        return '^hvx|hvi|hvs[0-9a-zA-Z]';
      case CryptoCurrency.xag:
      case CryptoCurrency.xau:
      case CryptoCurrency.xaud:
      case CryptoCurrency.xbtc:
      case CryptoCurrency.xcad:
      case CryptoCurrency.xchf:
      case CryptoCurrency.xcny:
      case CryptoCurrency.xeur:
      case CryptoCurrency.xgbp:
      case CryptoCurrency.xjpy:
      case CryptoCurrency.xnok:
      case CryptoCurrency.xnzd:
      case CryptoCurrency.xusd:
        return '[0-9a-zA-Z]';
      case  CryptoCurrency.hbar:
        return '[0-9a-zA-Z.]';
      case CryptoCurrency.zaddr:
        return '^zs[0-9a-zA-Z]{75}';
      case CryptoCurrency.zec:
        return '^t1[0-9a-zA-Z]{33}\$|^t3[0-9a-zA-Z]{33}\$';
      default:
        return '[0-9a-zA-Z]';
    }
  }

  static List<int> getLength(CryptoCurrency type) {
    switch (type) {
      case CryptoCurrency.xmr:
        return null;
      case CryptoCurrency.ada:
        return null;
      case CryptoCurrency.ape:
        return [42];
      case CryptoCurrency.avaxc:
        return [42];
      case CryptoCurrency.bch:
        return [42];
      case CryptoCurrency.bnb:
        return [42];
      case CryptoCurrency.btc:
        return null;
      case CryptoCurrency.dai:
        return [42];
      case CryptoCurrency.dash:
        return [34];
      case CryptoCurrency.eos:
        return [42];
      case CryptoCurrency.eth:
        return [42];
      case CryptoCurrency.ltc:
        return [34, 43];
      case CryptoCurrency.nano:
        return [64, 65];
      case CryptoCurrency.sc:
        return [76];
      case CryptoCurrency.sol:
        return [32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44];
      case CryptoCurrency.trx:
        return [34];
      case CryptoCurrency.usdc:
        return [42];
      case CryptoCurrency.usdcsol:
        return [32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44];
      case CryptoCurrency.usdt:
        return [34];
      case CryptoCurrency.usdterc20:
        return [42];
      case CryptoCurrency.usdttrc20:
        return [34];
      case CryptoCurrency.xlm:
        return [56];
      case CryptoCurrency.xrp:
        return null;
      case CryptoCurrency.xhv:
      case CryptoCurrency.xag:
      case CryptoCurrency.xau:
      case CryptoCurrency.xaud:
      case CryptoCurrency.xbtc:
      case CryptoCurrency.xcad:
      case CryptoCurrency.xchf:
      case CryptoCurrency.xcny:
      case CryptoCurrency.xeur:
      case CryptoCurrency.xgbp:
      case CryptoCurrency.xjpy:
      case CryptoCurrency.xnok:
      case CryptoCurrency.xnzd:
      case CryptoCurrency.xusd:
        return [98, 99, 106];
      case CryptoCurrency.btt:
        return [34];
      case CryptoCurrency.bttbsc:
        return [34];
      case CryptoCurrency.doge:
        return [34];
      case CryptoCurrency.firo:
        return [34];
      case CryptoCurrency.hbar:
        return [4, 5, 6, 7, 8, 9, 10, 11];
      case  CryptoCurrency.xvg:
        return [34];
      case  CryptoCurrency.zen:
        return [35];
      case CryptoCurrency.zaddr:
        return null;
      case CryptoCurrency.zec:
        return null;
      default:
        return [];
    }
  }
}
