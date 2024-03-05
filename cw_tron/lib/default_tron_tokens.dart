import 'package:cw_core/crypto_currency.dart';
import 'package:cw_tron/tron_token.dart';

class DefaultTronTokens {
  final List<TronToken> _defaultTokens = [];

  List<TronToken> get initialTronTokens => _defaultTokens.map((token) {
        String? iconPath;
        try {
          iconPath = CryptoCurrency.all
              .firstWhere((element) =>
                  element.title.toUpperCase() == token.symbol.split(".").first.toUpperCase())
              .iconPath;
        } catch (_) {}

        return TronToken.copyWith(token, iconPath, 'TRX');
      }).toList();
}
