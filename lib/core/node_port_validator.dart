import 'package:flutter/foundation.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/core/validator.dart';

class NodePortValidator extends TextValidator {
  NodePortValidator()
      : super(
            errorMessage: S.current.error_text_node_port,
            minLength: 1,
            maxLength: 5,
            pattern: '^[0-9]');
}
