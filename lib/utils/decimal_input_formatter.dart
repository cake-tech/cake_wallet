import 'package:flutter/services.dart';

class DecimalInputFormatter extends TextInputFormatter {
  const DecimalInputFormatter({this.maxDecimals = 7}) : assert(maxDecimals >= 0);

  final int maxDecimals;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;

    final regex = maxDecimals == 0
        ? RegExp(r'^\d*$')
        : RegExp('^\\d*([.,]\\d{0,$maxDecimals})?\$');
    return regex.hasMatch(text) ? newValue.copyWith(text: text.replaceAll(',', '.')) : oldValue;
  }
}
