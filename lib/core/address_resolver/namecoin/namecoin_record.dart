import 'dart:convert';

import 'package:cw_core/crypto_currency.dart';

class NamecoinRecord {
  static final RegExp _namePattern = RegExp(r'^[a-z0-9](?:[a-z0-9._-]{0,253}[a-z0-9])?$');

  static bool isNamecoinIdentifier(String input) => normalizeIdentifier(input) != null;

  static String? normalizeIdentifier(String input) {
    var value = input.trim().toLowerCase();
    if (value.endsWith('.')) value = value.substring(0, value.length - 1);

    if (value.endsWith('.bit')) value = 'd/${value.substring(0, value.length - 4)}';
    if (!value.startsWith('d/') && !value.startsWith('id/')) return null;

    final separator = value.indexOf('/');
    final name = value.substring(separator + 1);
    if (name.isEmpty || name.length > 255 || !_namePattern.hasMatch(name)) return null;
    if (name.contains('..')) return null;

    return '${value.substring(0, separator)}/$name';
  }

  /// Reads addresses keyed by Cake's unique, case-insensitive currency names.
  ///
  /// For example: {"btc":"bc1...", "xmr":"4...", "usdterc20":"0x..."}.
  /// A currency may also be an object with an "address" string.
  static Map<CryptoCurrency, String> parseAddresses(
    String rawValue, {
    List<CryptoCurrency> currencies = CryptoCurrency.all,
  }) {
    final dynamic decoded;
    try {
      decoded = json.decode(rawValue);
    } on FormatException {
      return const {};
    }

    if (decoded is! Map<String, dynamic>) return const {};

    final fields = <String, dynamic>{
      for (final entry in decoded.entries) entry.key.toLowerCase(): entry.value,
    };
    final result = <CryptoCurrency, String>{};

    for (final currency in currencies) {
      final dynamic field = fields[currency.name.toLowerCase()];
      final dynamic rawAddress = field is Map<String, dynamic> ? field['address'] : field;
      if (rawAddress is! String) continue;

      final address = rawAddress.trim();
      if (address.isNotEmpty) result[currency] = address;
    }

    return result;
  }
}
