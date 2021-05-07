import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/core/validator.dart';

class NodePortValidator extends TextValidator {
  NodePortValidator()
      : super(
            errorMessage: S.current.error_text_node_port,
            minLength: 0,
            maxLength: 5,
            pattern: '^[0-9]');
}
