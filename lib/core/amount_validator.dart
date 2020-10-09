import 'package:cake_wallet/core/validator.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/entities/wallet_type.dart';

class AmountValidator extends TextValidator {
  AmountValidator({WalletType type, bool isAutovalidate = false})
      : super(
            errorMessage: S.current.error_text_amount,
            pattern: _pattern(type),
            isAutovalidate: isAutovalidate,
            minLength: 0,
            maxLength: 0);

  static String _pattern(WalletType type) {
    switch (type) {
      case WalletType.monero:
        return '^([0-9]+([.\,][0-9]{0,12})?|[.\,][0-9]{1,12})\$';
      case WalletType.bitcoin:
        // FIXME: Incorrect pattern for bitcoin
        return '^([0-9]+([.\,][0-9]{0,12})?|[.\,][0-9]{1,12})\$';
      default:
        return '';
    }
  }
}

class AllAmountValidator extends TextValidator {
  AllAmountValidator() : super(
      errorMessage: S.current.error_text_amount,
      pattern: S.current.all,
      minLength: 0,
      maxLength: 0);
}
