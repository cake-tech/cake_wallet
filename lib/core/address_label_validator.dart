import 'package:cake_wallet/core/validator.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cw_core/wallet_type.dart';

class AddressLabelValidator extends TextValidator {
  AddressLabelValidator({WalletType? type})
      : super(
            errorMessage: S.current.error_text_subaddress_name,
            pattern: '''^[^`,'"]{1,20}\$''',
            minLength: 1,
            maxLength: 20);
}
