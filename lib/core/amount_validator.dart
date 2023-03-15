import 'package:cake_wallet/core/validator.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cw_core/crypto_currency.dart';

class AmountValidator extends TextValidator {
  AmountValidator({required CryptoCurrency currency, bool isAutovalidate = false}) {
    symbolsAmountValidator =
        SymbolsAmountValidator(isAutovalidate: isAutovalidate);
    decimalAmountValidator = DecimalAmountValidator(currency: currency);
  }

  late final SymbolsAmountValidator symbolsAmountValidator;

  late final DecimalAmountValidator decimalAmountValidator;

  String? call(String? value) => symbolsAmountValidator(value) ?? decimalAmountValidator(value);
}

class SymbolsAmountValidator extends TextValidator {
  SymbolsAmountValidator({required bool isAutovalidate})
      : super(
      errorMessage: S.current.error_text_amount,
      pattern: _pattern(),
      isAutovalidate: isAutovalidate,
      minLength: 0,
      maxLength: 0);

  static String _pattern() => '^([0-9]+([.\,][0-9]+)?|[.\,][0-9]+)\$';
}

class DecimalAmountValidator extends TextValidator {
  DecimalAmountValidator({required CryptoCurrency currency, bool isAutovalidate = false})
      : super(
            errorMessage: S.current.decimal_places_error,
            pattern: _pattern(currency),
            isAutovalidate: isAutovalidate,
            minLength: 0,
            maxLength: 0);

  static String _pattern(CryptoCurrency currency) {
    switch (currency) {
      case CryptoCurrency.xmr:
        return '^([0-9]+([.\,][0-9]{1,12})?|[.\,][0-9]{1,12})\$';
      case CryptoCurrency.btc:
        return '^([0-9]+([.\,][0-9]{1,8})?|[.\,][0-9]{1,8})\$';
      default:
        return '^([0-9]+([.\,][0-9]{1,12})?|[.\,][0-9]{1,12})\$';
    }
  }
}

class AllAmountValidator extends TextValidator {
  AllAmountValidator()
      : super(
            errorMessage: S.current.error_text_amount,
            pattern: S.current.all,
            minLength: 0,
            maxLength: 0);
}
