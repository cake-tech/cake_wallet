import 'package:cake_wallet/core/validator.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/domain/common/wallet_type.dart';

class AmountValidator extends TextValidator {
  AmountValidator({WalletType type})
      : super(
            errorMessage: S.current.error_text_amount,
            pattern: _pattern(type),
            minLength: 0,
            maxLength: 0);

  static String _pattern(WalletType type) {
    switch (type) {
      case WalletType.monero:
        return '^([0-9]+([.][0-9]{0,12})?|[.][0-9]{1,12}|ALL)\$';
      case WalletType.bitcoin:
        // FIXME: Incorrect pattern for bitcoin
        return '^([0-9]+([.][0-9]{0,12})?|[.][0-9]{1,12}|ALL)\$';
      default:
        return '';
    }
  }
}
