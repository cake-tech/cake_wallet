import "package:cake_wallet/new-ui/viewmodels/swap/util/exchange_limits.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  Money btc(String amount) => Money.parse(amount, CryptoCurrency.btc);

  group("ExchangeLimits", () {
    test("min and max in different currencies are rejected", () {
      expect(
        () => ExchangeLimits(min: btc("0.001"), max: Money.parse("20", CryptoCurrency.xmr)),
        throwsArgumentError,
      );
    });

    test("one side alone is fine", () {
      expect(ExchangeLimits(min: btc("0.001")).max, isNull);
      expect(ExchangeLimits(max: btc("20")).min, isNull);
    });
  });

  group("isWithinLimit", () {
    final limits = ExchangeLimits(min: btc("0.001"), max: btc("20"));

    test("an amount between the bounds is within", () {
      expect(limits.isWithinLimit(btc("2")), isTrue);
    });

    test("the bounds themselves are within", () {
      expect(limits.isWithinLimit(btc("0.001")), isTrue);
      expect(limits.isWithinLimit(btc("20")), isTrue);
    });

    test("one satoshi outside either bound is not", () {
      expect(limits.isWithinLimit(btc("0.00099999")), isFalse);
      expect(limits.isWithinLimit(btc("20.00000001")), isFalse);
    });

    test("a missing bound does not constrain that side", () {
      expect(ExchangeLimits(min: btc("0.001")).isWithinLimit(btc("1000000")), isTrue);
      expect(ExchangeLimits(max: btc("20")).isWithinLimit(btc("0.00000001")), isTrue);
    });

    test("no limits at all accepts anything, in any currency", () {
      expect(ExchangeLimits().isWithinLimit(btc("2")), isTrue);
      expect(ExchangeLimits().isWithinLimit(Money.parse("500", CryptoCurrency.xmr)), isTrue);
    });

    test("an amount in another currency is an error rather than a guess", () {
      expect(
        () => limits.isWithinLimit(Money.parse("2", CryptoCurrency.xmr)),
        throwsArgumentError,
      );
      expect(
        () => ExchangeLimits(max: btc("20")).isWithinLimit(Money.parse("2", CryptoCurrency.xmr)),
        throwsArgumentError,
      );
    });
  });
}
