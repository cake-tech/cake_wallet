import "package:cw_core/amount/money.dart";
import "package:cw_core/spl_token.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  group("SPL token raw amounts", () {
    test("6 decimal token renders raw base units", () {
      final jup = SPLToken(
        name: "Jupiter",
        symbol: "JUP",
        mint: "jup",
        mintAddress: "JUPyiwrYJFskUPiHa7hkeR8VUtAeFoSYbKedZNsDvCN",
        decimal: 6,
      );

      expect(Money(BigInt.from(100000), jup).toStringWithPrecision(), "0.1");
      expect(Money(BigInt.from(931614), jup).toStringWithPrecision(), "0.931614");
    });

    test("8 decimal token renders raw base units", () {
      final xstock = SPLToken(
        name: "Amazon xStock",
        symbol: "AMZNX",
        mint: "amznx",
        mintAddress: "mintAddressWithEightDecimals",
        decimal: 8,
      );

      expect(Money(BigInt.from(341694), xstock).toStringWithPrecision(), "0.00341694");
    });

    test("the same raw amount means different values per decimals", () {
      final raw = BigInt.from(100000);

      final six = SPLToken(
        name: "Six",
        symbol: "SIX",
        mint: "six",
        mintAddress: "mintAddressWithSixDecimals",
        decimal: 6,
      );

      final nine = SPLToken(
        name: "Nine",
        symbol: "NINE",
        mint: "nine",
        mintAddress: "mintAddressWithNineDecimals",
        decimal: 9,
      );

      final zero = SPLToken(
        name: "Zero",
        symbol: "ZERO",
        mint: "zero",
        mintAddress: "mintAddressWithZeroDecimals",
        decimal: 0,
      );

      expect(Money(raw, six).toStringWithPrecision(), "0.1");
      expect(Money(raw, nine).toStringWithPrecision(), "0.0001");
      expect(Money(raw, zero).toStringWithPrecision(), "100000");
    });
  });

  group("SPL token amount parsing", () {
    test("parses whole amounts for a zero decimal token", () {
      final zero = SPLToken(
        name: "Zero",
        symbol: "ZERO",
        mint: "zero",
        mintAddress: "mintAddressWithZeroDecimals",
        decimal: 0,
      );

      expect(Money.parse("5", zero).amount, BigInt.from(5));
      expect(Money.parse("0", zero).amount, BigInt.zero);
    });

    test("parses fractional amounts for a 6 decimal token", () {
      final jup = SPLToken(
        name: "Jupiter",
        symbol: "JUP",
        mint: "jup",
        mintAddress: "JUPyiwrYJFskUPiHa7hkeR8VUtAeFoSYbKedZNsDvCN",
        decimal: 6,
      );

      expect(Money.parse("0.1", jup).amount, BigInt.from(100000));
      expect(Money.parse("10.339089", jup).amount, BigInt.from(10339089));
    });

    test("rejects more fractional digits than the token has decimals", () {
      final zero = SPLToken(
        name: "Zero",
        symbol: "ZERO",
        mint: "zero",
        mintAddress: "mintAddressWithZeroDecimals",
        decimal: 0,
      );

      expect(() => Money.parse("5.5", zero), throwsFormatException);
    });
  });
}
