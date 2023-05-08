abstract class Validator<T> {
  Validator({required this.errorMessage, this.useAdditionalValidation});

  final String errorMessage;
  final bool Function(T)? useAdditionalValidation;

  bool isValid(T? value);

  String? call(T? value) => !isValid(value) ? errorMessage : null;
}

class TextValidator extends Validator<String> {
  TextValidator({
    bool Function(String)? useAdditionalValidation,
    this.minLength,
    this.maxLength,
    this.pattern,
    String errorMessage = '',
    this.length,
    this.isAutovalidate = false,
  }) : super(
            errorMessage: errorMessage,
            useAdditionalValidation: useAdditionalValidation);

  final int? minLength;
  final int? maxLength;
  final List<int>? length;
  final bool isAutovalidate;
  String? pattern;

  @override
  bool isValid(String? value) {
    if (value == null || value.isEmpty) {
      return isAutovalidate ? true : false;
    }

    return value.length > (minLength ?? 0) &&
        (length?.contains(value.length) ?? true) &&
        ((maxLength ?? 0) > 0 ? (value.length <= maxLength!) : true) &&
        (pattern != null
            ? (useAdditionalValidation != null &&
                    useAdditionalValidation!(value)) ||
                match(value)
            : true);
  }

  bool match(String value) =>
      pattern != null ? RegExp(pattern!).hasMatch(value) : false;
}
