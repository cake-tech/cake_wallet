import 'package:flutter_libmonero/core/validator.dart';
import 'package:flutter_libmonero/generated/i18n.dart';

class TemplateValidator extends TextValidator {
  TemplateValidator()
      : super(
            minLength: 0,
            maxLength: 0,
            pattern: '''^[^`,'"]{1,20}\$''',
            errorMessage: S.current.error_text_template);
}
