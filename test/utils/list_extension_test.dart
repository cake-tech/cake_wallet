import "package:cake_wallet/utils/list_extension.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  test("max and min pick the extremes wherever they sit", () {
    expect(["b", "c", "a"].max, "c");
    expect(["b", "c", "a"].min, "a");
    expect([DateTime(2026, 3), DateTime(2026, 9), DateTime(2026, 1)].max, DateTime(2026, 9));
    expect([DateTime(2026, 3), DateTime(2026, 9), DateTime(2026, 1)].min, DateTime(2026, 1));
  });

  test("money compares by amount", () {
    final amounts = [
      Money.parse("0.5", CryptoCurrency.btc),
      Money.parse("20", CryptoCurrency.btc),
      Money.parse("0.001", CryptoCurrency.btc),
    ];

    expect(amounts.max, Money.parse("20", CryptoCurrency.btc));
    expect(amounts.min, Money.parse("0.001", CryptoCurrency.btc));
  });

  test("a single element is both the max and the min", () {
    expect(["only"].max, "only");
    expect(["only"].min, "only");
  });

  test("works on any iterable, not only lists", () {
    expect({"b", "a", "c"}.max, "c");
    expect(["bb", "a", "ccc"].map((s) => s.length.toString()).min, "1");
  });

  test("an empty iterable has no max or min", () {
    expect(() => <String>[].max, throwsStateError);
    expect(() => <String>[].min, throwsStateError);
  });
}
