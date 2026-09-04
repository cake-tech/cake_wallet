import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/core/validator.dart';

class WalletNameValidator extends TextValidator {
  WalletNameValidator()
      : super(
            errorMessage: S.current.error_text_wallet_name,
            pattern: '^[a-zA-Z0-9\- ]+\$',
            minLength: 1,
            maxLength: 33);
}

String walletNameToDisplay(
    String walletName, {
      int maxLength = 25,
      int truncateAt = 20,
      bool showWalletType = false,
    }) {
  final parts = walletName.split("_");
  final name = parts.first;
  final walletType = parts.length > 1 ? parts[1] : null;

  final displayName =
  name.length > maxLength ? "${name.substring(0, truncateAt)}..." : name;

  if (showWalletType && walletType != null) {
    return "${displayName} ($walletType)";
  }

  return displayName;
}
