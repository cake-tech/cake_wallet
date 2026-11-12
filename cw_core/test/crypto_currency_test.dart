import "package:cw_core/crypto_currency.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  test("currency raws are unique", () {
    final currencies = {
      ...CryptoCurrency.all,
      ...CryptoCurrency.havenCurrencies,
      ...CryptoCurrency.zcashCurrencies,
    };
    expect(currencies.map((c) => c.raw).toSet(), hasLength(currencies.length));
  });
}
