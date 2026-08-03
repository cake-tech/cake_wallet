import 'dart:async';
import 'dart:convert';

import 'package:cake_wallet/core/address_validator.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';

class ZcashNamesRecord {
  static final Uri _mainnetEndpoint = Uri.parse('https://main.zcashnames.com');

  static final RegExp _nameRegExp = RegExp(r'^[A-Za-z0-9_-]{1,63}$');

  static Future<String?> fetchZcashNamesAddress(String input) async {
    final name = _extractName(input);
    if (name == null) return null;

    try {
      final response = await ProxyWrapper().post(
        clearnetUri: _mainnetEndpoint,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'jsonrpc': '2.0',
          'id': 1,
          'method': 'resolve',
          'params': {'query': name},
        }),
      );

      if (response.statusCode != 200) {
        printV('ZcashNames: non-200 status ${response.statusCode} for $name');
        return null;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;
      if (decoded['error'] != null) return null;

      final result = decoded['result'];
      if (result is! Map<String, dynamic>) return null;

      final address = result['address'];
      if (address is! String || address.isEmpty) return null;

      if (!_isValidZcashAddress(address)) {
        printV('ZcashNames: returned address failed validation for $name');
        return null;
      }
      return address;
    } catch (e) {
      printV('ZcashNames: lookup failed for $name: $e');
      return null;
    }
  }

  static String? _extractName(String input) {
    final lower = input.toLowerCase().trim();
    String? raw;
    if (lower.endsWith('.zcash')) {
      raw = lower.substring(0, lower.length - '.zcash'.length);
    } else if (lower.endsWith('.zec')) {
      raw = lower.substring(0, lower.length - '.zec'.length);
    }
    if (raw == null || raw.isEmpty) return null;
    if (!_nameRegExp.hasMatch(raw)) return null;
    return raw;
  }

  static bool _isValidZcashAddress(String address) {
    final pattern = AddressValidator.getAddressFromStringPattern(CryptoCurrency.zec);
    if (pattern == null) return false;
    return RegExp('^(?:$pattern)\$').hasMatch(address);
  }
}
