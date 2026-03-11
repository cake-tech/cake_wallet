import 'package:intl/intl.dart';

double cryptoAmountToDouble({required num amount, required num divider}) => amount / divider;

extension MaxDecimals on String {
  String withMaxDecimals(int maxDecimals) {
    var parts = split(".");

    if (parts.length > 2) {
      parts = [parts.first, parts.sublist(1, parts.length).join("")];
    }

    if (parts.length == 2 && parts[1].length > maxDecimals) {
      parts[1] = parts[1].substring(0, maxDecimals);
    }

    return parts.join(".");
  }


  /// Format a stringified number to a localized representation
  ///     1.000.000,00 in de_DE
  ///     1’000’000.00 in de_CH
  ///     1,000,000.00 in en_US
  ///
  /// Can also handle amounts suffixed with a Symbol
  ///     1.000.000,00 XMR in de_DE
  ///     1’000’000.00 XMR in de_CH
  ///     1,000,000.00 XMR in en_US
  ///
  /// Can also handle amounts prefixed with a size relational operator
  ///     < 1.000.000,00 XMR in de_DE
  ///     > 1’000’000.00 XMR in de_CH
  ///     < 1,000,000.00 XMR in en_US
  ///
  /// DO NOT PARSE THE LOCALIZED STRING TO A NUMBER IF YOU WANT TO KEEP YOUR SANITY!
  String withLocalSeperator([String? locale]) {
    if (contains(" ")) {
      final parts = split(" ");

      if ([">", "<"].contains(parts.first)) {
        final result = [parts.first, parts[1].withLocalSeperator(locale)];
        if (parts.length > 2) result.addAll(parts.sublist(2));

        return result.join(" ");
      }

      return [parts.first.withLocalSeperator(locale), ...parts.sublist(1)].join(" ");
    }

    final formater = NumberFormat("#,###", locale);
    final parts = replaceAll(",", "").split(".");
    if (parts.first.contains("< 0")) parts.first = "0";

    return [formater.format(int.tryParse(parts.first) ?? 0), ...parts.sublist(1)]
        .join(formater.symbols.DECIMAL_SEP);
  }
}
