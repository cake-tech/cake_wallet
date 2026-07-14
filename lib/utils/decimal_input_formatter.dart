import 'package:cake_wallet/generated/i18n.dart';
import 'package:flutter/services.dart';

class DecimalInputFormatter extends TextInputFormatter {
  const DecimalInputFormatter({this.maxDecimals = 7}) : assert(maxDecimals >= 0);

  final int maxDecimals;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;

    if (S.current.all.startsWith(text)) {
      return const TextEditingValue(
        text: "",
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final regex = maxDecimals == 0 ? RegExp(r'^\d*$') : RegExp('^\\d*([.,]\\d{0,$maxDecimals})?\$');
    return regex.hasMatch(text) ? newValue.copyWith(text: text.replaceAll(',', '.')) : oldValue;
  }
}
