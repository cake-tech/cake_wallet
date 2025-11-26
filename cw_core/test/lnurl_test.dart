import 'package:cw_core/lnurl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('lnurl', () {
    test('decode lnurl', () {
      final content = decodeLNURL(
          "lnurl1dp68gurn8ghj7cmpddjjucmpwd5z7tnhv4kxctttdehhwm30d3h82unvwqhkkmmwwd6xj9vpzq4");
      expect(content, Uri.parse("https://cake.cash/.well-known/lnurlp/konsti"));
    });

    test('encode lnurl', () {
      final content = encodeLNURL("https://cake.cash/.well-known/lnurlp/konsti");
      expect(content,
          "lnurl1dp68gurn8ghj7cmpddjjucmpwd5z7tnhv4kxctttdehhwm30d3h82unvwqhkkmmwwd6xj9vpzq4");
    });
  });
}
