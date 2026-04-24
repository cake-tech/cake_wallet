import 'package:cw_core/crypto_currency.dart';

class TradeCurrencySnapshot {
  TradeCurrencySnapshot._();

  static CryptoCurrency? fromLegacyHive({
    required int raw,
    String? displayTitleTag,
  }) {
    if (raw >= 0) {
      final curr = CryptoCurrency.safeDeserialize(raw: raw);
      if (curr != null) return curr;
    }

    return _parseLegacyTitleTag(displayTitleTag);
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
