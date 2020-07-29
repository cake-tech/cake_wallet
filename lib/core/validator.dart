import 'package:flutter/foundation.dart';

abstract class Validator<T> {
  Validator({@required this.errorMessage});

  final String errorMessage;

  bool isValid(T value);

  String call(T value) => !isValid(value) ? errorMessage : null;
}

class TextValidator extends Validator<String> {
  TextValidator(
      {this.minLength,
      this.maxLength,
      this.pattern,
      this.length,
      String errorMessage})
      : super(errorMessage: errorMessage);

  final int minLength;
  final int maxLength;
  final List<int> length;
  String pattern;

  @override
  bool isValid(String value) {
    if (value == null || value.isEmpty) {
      return false;
    }

    return value.length > (minLength ?? 0) &&
        (length?.contains(value.length) ?? true) &&
        ((maxLength ?? 0) > 0 ? (value.length <= maxLength) : true) &&
        (pattern != null ? match(value) : true);
  }

  bool match(String value) => RegExp(pattern).hasMatch(value);
}

class WalletNameValidator extends TextValidator {
  WalletNameValidator()
      : super(minLength: 1, maxLength: 15, pattern: '^[a-zA-Z0-9_]\$');
}