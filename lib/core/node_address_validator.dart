import 'package:cake_wallet/core/validator.dart';
import 'package:cake_wallet/generated/i18n.dart';

class NodeAddressValidator extends TextValidator {
  NodeAddressValidator()
      : super(
            errorMessage: S.current.error_text_node_address,
            pattern:
                '^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\$|^[0-9a-zA-Z.\-]+\$');
}
