import 'dart:convert';

import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';

class WellKnownRecord {
  WellKnownRecord({
    required this.address,
    required this.alias,
    required this.imageUrl,
    required this.title,
  });

  final String address;
  final String alias;
  final String? imageUrl;
  final String? title;

  static const _jsonLocation = {CryptoCurrency.nano: 'nano-currency'};

  static Future<WellKnownRecord?> fetch(
    String username,
    CryptoCurrency currency,
  ) async {
    final location = _jsonLocation[currency];
    if (location == null) {
      printV('well-known: unsupported coin $currency');
      return null;
    }

    final parts = username.split('@');
    if (parts.length < 2) {
      printV('well-known: missing @ in "$username"');
      return null;
    }
    final alias = (parts.length == 3 ? parts[1] : parts[0]).trim();
    final domain = parts.last.trim();
    final encoded = Uri.encodeComponent(alias.isEmpty ? '_' : alias);

    final uri = Uri.https(
      domain,
      '/.well-known/$location.json',
      {'names': encoded},
    );

    try {
      final res = await ProxyWrapper().get(
        clearnetUri: uri,
        headers: {'Accept': 'application/json'},
      );

      final cType = res.headers['content-type']?.toLowerCase() ?? '';
      if (res.statusCode != 200 || !cType.contains('application/json')) {
        printV('well-known: $uri → ${res.statusCode} $cType');
        return null;
      }

      final body = json.decode(res.body) as Map<String, dynamic>;
      final items = body['names'] as List<dynamic>? ?? const [];

      for (final raw in items.whereType<Map>()) {
        if (raw['name'].toString().toLowerCase() == alias.toLowerCase()) {
          return WellKnownRecord(
            address: raw['address']?.toString() ?? '',
            alias: alias,
            imageUrl: raw['image']?.toString(),
            title: raw['name']?.toString(),
          );
        }
      }
      printV('well-known: alias "$alias" not found in list');
    } catch (e) {
      printV('well-known: network / JSON error → $e');
    }
    return null;
  }
}
