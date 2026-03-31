import 'dart:convert';

import 'package:cw_core/crypto_currency.dart';

class TradeCurrencySnapshot {
  TradeCurrencySnapshot._();

  static const int _version = 1;

  /// JSON stored in SQLite. Null means no asset snapshot.
  static String? encode(CryptoCurrency? c) {
    if (c == null) return null;

    final map = <String, dynamic>{
      'version': _version,
      'title': c.title,
      'name': c.name,
      'decimals': c.decimals,
      'raw': c.raw,
    };

    if (c.tag != null && c.tag!.isNotEmpty) {
      map['tag'] = c.tag;
    }
    if (c.fullName != null && c.fullName!.isNotEmpty) {
      map['fullName'] = c.fullName;
    }
    if (c.iconPath != null && c.iconPath!.isNotEmpty) {
      map['iconPath'] = c.iconPath;
    }
    if (c.flatIconPath != null && c.flatIconPath!.isNotEmpty) {
      map['flatIconPath'] = c.flatIconPath;
    }
    if (c.chainIconPath != null && c.chainIconPath!.isNotEmpty) {
      map['chainIconPath'] = c.chainIconPath;
    }
    return jsonEncode(map);
  }

  static CryptoCurrency? decode(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) return null;

    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;

      if (map['version'] != _version) return null;

      return CryptoCurrency(
        title: map['title'] as String? ?? '',
        raw: (map['raw'] as int?) ?? -1,
        name: map['name'] as String? ?? '',
        decimals: (map['decimals'] as int?) ?? 8,
        tag: map['tag'] as String?,
        fullName: map['fullName'] as String?,
        iconPath: map['iconPath'] as String?,
        flatIconPath: map['flatIconPath'] as String?,
        chainIconPath: map['chainIconPath'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  /// For one-time migration from Hive to SQLite, converts legacy currency to JSON string.
  static String? fromLegacyHive({
    required int raw,
    String? displayTitleTag,
  }) {
    if (raw >= 0) {
      final curr = CryptoCurrency.safeDeserialize(raw: raw);
      if (curr != null) return encode(curr);
    }

    final parsed = _parseLegacyTitleTag(displayTitleTag);

    if (parsed != null) return encode(parsed);

    return null;
  }

  static CryptoCurrency? _parseLegacyTitleTag(String? titleTag) {
    if (titleTag == null || titleTag.isEmpty) return null;

    final idx = titleTag.indexOf('_');
    if (idx < 0) {
      return CryptoCurrency(
        title: titleTag,
        name: '',
        raw: -1,
        decimals: 1,
      );
    }

    final title = titleTag.substring(0, idx);

    var tag = titleTag.substring(idx + 1);

    if (tag.contains('ARB')) tag = 'ARB';

    return CryptoCurrency(
      title: title,
      tag: tag.isNotEmpty ? tag : null,
      name: '',
      raw: -1,
      decimals: 1,
    );
  }
}
