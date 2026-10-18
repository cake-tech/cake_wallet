import "package:cw_core/amount/money.dart";
import "package:cw_core/amount/money_double.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/parse_fixed.dart";
import "package:flutter_test/flutter_test.dart";

/// Every non-finite spelling that `double.tryParse` accepts.
///
/// These matter because a `double`-based amount guard cannot reject them:
/// `Infinity <= 0` is false and *every* comparison against `NaN` is false, so a
/// non-finite amount sails through an `if (amount <= 0) throw` check and then
/// collapses to zero once it reaches Money/BigInt -- i.e. a zero-amount
/// transaction that passed validation. The Money layer is the enforcement point
/// for that invariant, so pin it here.
const nonFiniteSpellings = <String>[
  "Infinity",
  "+Infinity",
  "-Infinity",
  "NaN",
  "1e999", // overflows to Infinity as a double
  "1E400",
  "  Infinity ",
];

void main() {
  group("non-finite amounts", () {
    test("double.tryParse accepts them (this is why Money must reject them)", () {
      for (final spelling in nonFiniteSpellings) {
        final parsed = double.tryParse(spelling);
        expect(parsed, isNotNull, reason: "double.tryParse rejected $spelling");
        expect(parsed!.isFinite, isFalse, reason: "$spelling parsed as finite");
        // The point of the whole exercise: a `<= 0` guard does not stop these.
        if (!parsed.isNegative) {
          expect(parsed <= 0, isFalse, reason: "$spelling was caught by a <= 0 guard");
        }
      }
    });

    test("Money.tryParse returns null for every non-finite spelling", () {
      for (final spelling in nonFiniteSpellings) {
        expect(
          Money.tryParse(spelling, CryptoCurrency.btc),
          isNull,
          reason: "Money.tryParse accepted $spelling",
        );
        expect(
          Money.tryParse(spelling, CryptoCurrency.btc, strictParsing: false),
          isNull,
          reason: "Money.tryParse(strictParsing: false) accepted $spelling",
        );
      }
    });

    test("Money.parse throws for every non-finite spelling", () {
      for (final spelling in nonFiniteSpellings) {
        expect(
          () => Money.parse(spelling, CryptoCurrency.btc),
          throwsA(isA<FormatException>()),
          reason: "Money.parse accepted $spelling",
        );
      }
    });

    test("CryptoCurrency.tryParseAmount returns null, parseAmount throws", () {
      for (final spelling in nonFiniteSpellings) {
        expect(CryptoCurrency.btc.tryParseAmount(spelling), isNull, reason: spelling);
        expect(
          () => CryptoCurrency.btc.parseAmount(spelling),
          throwsA(isA<FormatException>()),
          reason: spelling,
        );
      }
    });

    test("tryParseFixed returns null / parseFixed throws (the underlying gate)", () {
      for (final spelling in nonFiniteSpellings) {
        expect(tryParseFixed(spelling, 8), isNull, reason: spelling);
        expect(
          () => parseFixed(spelling, 8),
          throwsA(isA<FormatException>()),
          reason: spelling,
        );
      }
    });

    test("double.tryToMoney returns null for non-finite doubles", () {
      // Relied on by ExchangeViewModel.changeReceiveAmount/changeDepositAmount, which
      // divide by `bestRate` and can produce Infinity when the rate is still 0.
      expect(double.infinity.tryToMoney(CryptoCurrency.btc), isNull);
      expect(double.negativeInfinity.tryToMoney(CryptoCurrency.btc), isNull);
      expect(double.nan.tryToMoney(CryptoCurrency.btc), isNull);
    });

    test("a rejected amount funnels to Money.zero, which is the sweep-all sentinel", () {
      // Why the cw_monero/cw_wownero guards exist. MONERO_Wallet_createTransaction:
      //     Monero::optional<uint64_t> optAmount;
      //     if (amount != 0) { optAmount = amount; }
      // so amount == 0 means "no amount given" and wallet2 sweeps the whole account.
      // Output.cryptoAmountMoney falls back to Money.zero on any parse failure, and a
      // zero Money stringifies to an all-zeros decimal -- exactly the value the native
      // layer reads as "send everything". Nothing between them may treat 0 as an amount.
      for (final spelling in nonFiniteSpellings) {
        final fallback =
            CryptoCurrency.btc.tryParseAmount(spelling) ?? Money.zero(CryptoCurrency.xmr);
        expect(fallback.amount, BigInt.zero, reason: spelling);
      }

      final zeroXmr = Money.zero(CryptoCurrency.xmr);
      expect(zeroXmr.amount, BigInt.zero);
      expect(double.tryParse(zeroXmr.toString()), 0.0,
          reason: "a zero Money must stringify to a numeric zero, i.e. the sweep-all sentinel");
      expect(RegExp(r"^0(\.0+)?$").hasMatch(zeroXmr.toString()), isTrue,
          reason: "unexpected zero rendering: ${zeroXmr.toString()}");

      // One piconero is NOT zero -- the guards must not reject genuine dust.
      expect(Money(BigInt.one, CryptoCurrency.xmr).sign, 1);
      expect(double.parse(Money(BigInt.one, CryptoCurrency.xmr).toString()) > 0, isTrue);
    });

    test("finite amounts still round-trip (guard did not over-reject)", () {
      expect(Money.tryParse("0", CryptoCurrency.btc)!.amount, BigInt.zero);
      expect(Money.tryParse("1", CryptoCurrency.btc)!.amount, BigInt.from(100000000));
      expect(Money.tryParse("0.00000001", CryptoCurrency.btc)!.amount, BigInt.one);
      expect(1.5.tryToMoney(CryptoCurrency.btc)!.amount, BigInt.from(150000000));
    });
  });
}
