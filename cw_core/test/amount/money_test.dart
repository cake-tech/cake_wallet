import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  group("Money", () {
    test("parse", () {
      var money = Money.parse("1", CryptoCurrency.btc);
      expect(money.amount, BigInt.from(100000000));

      money = Money.parse("-1", CryptoCurrency.btc);
      expect(money.amount, BigInt.from(-100000000));

      money = Money.parse("1.11", CryptoCurrency.btc);
      expect(money.amount, BigInt.from(111000000));

      money = Money.parse("-1.11", CryptoCurrency.btc);
      expect(money.amount, BigInt.from(-111000000));

      money = Money.parse("-.11", CryptoCurrency.btc);
      expect(money.amount, BigInt.from(-11000000));

      money = Money.parse(".11", CryptoCurrency.btc);
      expect(money.amount, BigInt.from(11000000));

      // Invalid representation
      expect(() => Money.parse("1,11", CryptoCurrency.btc), throwsFormatException);

      // To many decimals
      expect(() => Money.parse("-1.0000000000000001", CryptoCurrency.btc), throwsFormatException);

      money = Money.parse("1", CryptoCurrency.btc, isBaseUnit: true);
      expect(money.amount, BigInt.from(1));

      money = Money.parse("0", CryptoCurrency.btc, isBaseUnit: true);
      expect(money.amount, BigInt.from(0));

      money = Money.parse("-1", CryptoCurrency.btc, isBaseUnit: true);
      expect(money.amount, BigInt.from(-1));

      // canonical representation when expecting base units
      expect(() => Money.parse("1.0", CryptoCurrency.btc, isBaseUnit: true), throwsFormatException);
    });

    test("tryParse", () {
      var money = Money.tryParse("1", CryptoCurrency.btc);
      expect(money?.amount, BigInt.from(100000000));

      money = Money.tryParse("-1", CryptoCurrency.btc);
      expect(money?.amount, BigInt.from(-100000000));

      money = Money.tryParse("1.11", CryptoCurrency.btc);
      expect(money?.amount, BigInt.from(111000000));

      money = Money.tryParse("-1.11", CryptoCurrency.btc);
      expect(money?.amount, BigInt.from(-111000000));

      money = Money.tryParse("-.11", CryptoCurrency.btc);
      expect(money?.amount, BigInt.from(-11000000));

      money = Money.tryParse(".11", CryptoCurrency.btc);
      expect(money?.amount, BigInt.from(11000000));

      // Invalid representation
      money = Money.tryParse("1,11", CryptoCurrency.btc);
      expect(money?.amount, isNull);

      // To many decimals
      money = Money.tryParse("-1.0000000000000001", CryptoCurrency.btc);
      expect(money?.amount, isNull);

      money = Money.tryParse("1", CryptoCurrency.btc, isBaseUnit: true);
      expect(money?.amount, BigInt.from(1));

      money = Money.tryParse("0", CryptoCurrency.btc, isBaseUnit: true);
      expect(money?.amount, BigInt.from(0));

      money = Money.tryParse("-1", CryptoCurrency.btc, isBaseUnit: true);
      expect(money?.amount, BigInt.from(-1));

      // canonical representation when expecting base units
      money = Money.tryParse("1.0", CryptoCurrency.btc, isBaseUnit: true);
      expect(money?.amount, isNull);
    });

    test("sign", () {
      expect(Money(BigInt.from(0), CryptoCurrency.btc).sign, 0);

      expect(Money(BigInt.from(1), CryptoCurrency.btc).sign, 1);

      expect(Money(BigInt.from(10), CryptoCurrency.btc).sign, 1);

      expect(Money(BigInt.from(-1), CryptoCurrency.btc).sign, -1);

      expect(Money(BigInt.from(-10), CryptoCurrency.btc).sign, -1);
    });

    test("isZero", () {
      expect(Money(BigInt.from(0), CryptoCurrency.btc).isZero, isTrue);

      expect(Money(BigInt.from(1), CryptoCurrency.btc).isZero, isFalse);

      expect(Money(BigInt.from(-1), CryptoCurrency.btc).isZero, isFalse);
    });

    test("isNegative", () {
      expect(Money(BigInt.from(0), CryptoCurrency.btc).isNegative, isFalse);

      expect(Money(BigInt.from(1), CryptoCurrency.btc).isNegative, isFalse);

      expect(Money(BigInt.from(-1), CryptoCurrency.btc).isNegative, isTrue);
    });

    group("Comparison", () {
      final fourBitcoin = Money(BigInt.from(400000000), CryptoCurrency.btc);
      final fiveBitcoin = Money(BigInt.from(500000000), CryptoCurrency.btc);
      final sixBitcoin = Money(BigInt.from(600000000), CryptoCurrency.btc);

      final fiveMonero = Money.parse("5", CryptoCurrency.xmr);

      test("==", () {
        expect(fiveBitcoin, equals(Money(BigInt.from(500000000), CryptoCurrency.btc)));
        expect(fiveBitcoin, isNot(equals(fourBitcoin)));
        expect(fiveBitcoin, isNot(equals(sixBitcoin)));
        expect(fiveBitcoin, isNot(equals(fiveMonero)));
        // intentional check of incompatible types.
        // ignore: unrelated_type_equality_checks
        expect(fiveBitcoin == "Not money", equals(false));
      });

      test("<", () {
        expect(fiveBitcoin < sixBitcoin, isTrue);
        expect(fiveBitcoin < fiveBitcoin, isFalse);
        expect(fiveBitcoin < fourBitcoin, isFalse);

        // Cannot compare money in different currencies:
        expect(() => fiveBitcoin < fiveMonero, throwsArgumentError);
      });

      test("<=", () {
        expect(fiveBitcoin <= sixBitcoin, isTrue);
        expect(fiveBitcoin <= fiveBitcoin, isTrue);
        expect(fiveBitcoin <= fourBitcoin, isFalse);

        // Cannot compare money in different currencies:
        expect(() => fiveBitcoin <= fiveMonero, throwsArgumentError);
      });

      test(">", () {
        expect(fiveBitcoin > fourBitcoin, isTrue);
        expect(fiveBitcoin > fiveBitcoin, isFalse);
        expect(fiveBitcoin > sixBitcoin, isFalse);

        // Cannot compare money in different currencies:
        expect(() => fiveBitcoin > fiveMonero, throwsArgumentError);
      });

      test(">=", () {
        expect(fiveBitcoin >= fourBitcoin, isTrue);
        expect(fiveBitcoin >= fiveBitcoin, isTrue);
        expect(fiveBitcoin >= sixBitcoin, isFalse);

        // Cannot compare money in different currencies:
        expect(() => fiveBitcoin >= fiveMonero, throwsArgumentError);
      });

      test("conformance to Comparable", () {
        expect(fiveBitcoin, isA<Comparable<Money>>());

        expect(fiveBitcoin.compareTo(fiveBitcoin), isZero);
        expect(fiveBitcoin.compareTo(fourBitcoin), isPositive);
        expect(fiveBitcoin.compareTo(sixBitcoin), isNegative);
        expect(() => fiveBitcoin.compareTo(fiveMonero), throwsArgumentError);
      });
    });

    group("Math", () {
      test("+", () {
        final oneBitcoin = Money.parse("1", CryptoCurrency.btc);
        final twoBitcoin = Money.parse("2", CryptoCurrency.btc);
        final threeBitcoin = Money.parse("3", CryptoCurrency.btc);

        expect(oneBitcoin + twoBitcoin, equals(threeBitcoin));
      });

      test("cannot add different currencies", () {
        final oneBitcoin = Money(BigInt.one, CryptoCurrency.btc);
        final oneMonero = Money(BigInt.one, CryptoCurrency.xmr);

        expect(() => oneBitcoin + oneMonero, throwsArgumentError);
      });

      test("invert money", () {
        final oneSatoshi = Money(BigInt.one, CryptoCurrency.btc);
        final negativeOneSatoshi = Money(BigInt.from(-1), CryptoCurrency.btc);

        expect(-oneSatoshi, equals(negativeOneSatoshi));
        expect(-negativeOneSatoshi, equals(oneSatoshi));
      });

      test("-", () {
        final oneSatoshi = Money(BigInt.one, CryptoCurrency.btc);
        final twoSatoshi = Money(BigInt.two, CryptoCurrency.btc);
        final threeSatoshi = Money(BigInt.from(3), CryptoCurrency.btc);

        expect(threeSatoshi - oneSatoshi, equals(twoSatoshi));
      });

      test("cannot subtract different currencies", () {
        final oneSatoshi = Money(BigInt.one, CryptoCurrency.btc);
        final oneMonero = Money(BigInt.one, CryptoCurrency.xmr);

        expect(() => oneSatoshi - oneMonero, throwsArgumentError);
      });

      test("*", () {
        final zeroSatoshi = Money(BigInt.zero, CryptoCurrency.btc);
        final oneSatoshi = Money(BigInt.one, CryptoCurrency.btc);
        final twoSatoshi = Money(BigInt.two, CryptoCurrency.btc);

        expect(oneSatoshi * BigInt.zero, equals(zeroSatoshi));
        expect(oneSatoshi * BigInt.two, equals(twoSatoshi));
        expect(oneSatoshi * BigInt.from(-2), equals(-twoSatoshi));
      });

      group("/", () {
        final threeBI = BigInt.from(3);
        final fourBI = BigInt.from(4);

        final negThreeBI = BigInt.from(-3);
        final negFourBI = BigInt.from(-4);

        test("rounds down when fractional part is < 0.5", () {
          expect((Money(BigInt.from(10), CryptoCurrency.btc) / threeBI).amount, threeBI);
          expect((Money(BigInt.from(-10), CryptoCurrency.btc) / threeBI).amount, negThreeBI);
          expect((Money(BigInt.from(10), CryptoCurrency.btc) / negThreeBI).amount, negThreeBI);
          expect((Money(BigInt.from(-10), CryptoCurrency.btc) / negThreeBI).amount, threeBI);
        });

        test("rounds up when fractional part is > 0.5", () {
          expect((Money(BigInt.from(11), CryptoCurrency.btc) / threeBI).amount, fourBI); // 3.66...
          expect((Money(BigInt.from(-11), CryptoCurrency.btc) / threeBI).amount, negFourBI);
          expect((Money(BigInt.from(11), CryptoCurrency.btc) / negThreeBI).amount, negFourBI);
          expect((Money(BigInt.from(-11), CryptoCurrency.btc) / negThreeBI).amount, fourBI);
        });

        test("rounds AWAY from zero when fractional part is exactly 0.5 (Ties)", () {
          // 5 / 2 = 2.5 -> 3
          expect((Money(BigInt.from(5), CryptoCurrency.btc) / BigInt.two).amount, threeBI);
          // -5 / 2 = -2.5 -> -3
          expect((Money(BigInt.from(-5), CryptoCurrency.btc) / BigInt.two).amount, negThreeBI);
          // 5 / -2 = -2.5 -> -3
          expect((Money(BigInt.from(5), CryptoCurrency.btc) / -BigInt.two).amount, negThreeBI);
          // -5 / -2 = 2.5 -> 3
          expect((Money(BigInt.from(-5), CryptoCurrency.btc) / -BigInt.two).amount, threeBI);
        });

        test("handles zero numerator correctly", () {
          expect((Money(BigInt.zero, CryptoCurrency.btc) / BigInt.from(5)).amount, BigInt.zero);
          expect((Money(BigInt.zero, CryptoCurrency.btc) / BigInt.from(-5)).amount, BigInt.zero);
        });

        test("throws Exception on division by zero", () {
          expect(
            () => Money(BigInt.from(5), CryptoCurrency.btc) / BigInt.zero,
            throwsA(isA<Exception>()),
          );
        });

        test("handles very large BigInts without precision loss", () {
          // A number that would lose precision if converted to a standard double
          final hugeA = BigInt.parse("10000000000000000000000000000000000005");
          final hugeB = BigInt.parse("10");
          // 1000...005 / 10 = 1000...000.5 -> Should round up to 1000...001
          final expected = BigInt.parse("1000000000000000000000000000000000001");

          expect((Money(hugeA, CryptoCurrency.btc) / hugeB).amount, expected);
        });

        test("handles exact division perfectly", () {
          expect(
            (Money(BigInt.from(100), CryptoCurrency.btc) / BigInt.from(20)).amount,
            BigInt.from(5),
          );
          expect(
            (Money(BigInt.from(-100), CryptoCurrency.btc) / BigInt.from(20)).amount,
            BigInt.from(-5),
          );
        });
      });
    });

    group("copyWith", () {
      final money = Money.parse("1", CryptoCurrency.btc);

      test("currency", () {
        final copy = money.copyWith(currency: CryptoCurrency.eth);
        expect(copy.amount, equals(BigInt.parse("1000000000000000000")));
        expect(copy.currency.decimals, equals(18));
        expect(copy.toString(), "1");
      });

      test("currency nano", () {
        final copy = money.copyWith(currency: CryptoCurrency.nano);
        expect(copy.amount, equals(BigInt.parse("1000000000000000000000000000000")));
        expect(copy.currency.decimals, equals(30));
        expect(copy.toString(), "1");
      });

      test("amount", () {
        final copy = money.copyWith(amount: BigInt.one);
        expect(copy.amount, BigInt.one);
        expect(copy.currency.decimals, 8);
      });

      test("amount and currency", () {
        final copy = money.copyWith(amount: BigInt.one);
        expect(copy.amount, BigInt.one);
        expect(copy.currency.decimals, 8);
      });
    });

    group("toStringWithPrecision", () {
      test("with fractionalDigits and padded with zeros", () {
        final money = Money.parse("1", CryptoCurrency.btc);
        expect(money.amount, equals(BigInt.parse("100000000")));
        expect(money.currency.decimals, equals(8));
        expect(money.toStringWithPrecision(fractionalDigits: 5, trimZeros: false), "1.00000");
      });

      test("using base unit sats", () {
        final money = Money.parse("1", CryptoCurrency.btc);
        expect(money.amount, equals(BigInt.parse("100000000")));
        expect(money.currency.decimals, equals(8));
        expect(money.toStringWithPrecision(useBaseUnit: true), "100000000");
      });
    });

    group("toStringWithSymbol", () {
      test("with fractionalDigits and padded with zeros", () {
        final money = Money.parse("1", CryptoCurrency.btc);
        expect(money.amount, equals(BigInt.parse("100000000")));
        expect(money.currency.decimals, equals(8));
        expect(money.toStringWithSymbol(fractionalDigits: 5, trimZeros: false), "1.00000 BTC");
      });

      test("using base unit sats", () {
        final money = Money.parse("1", CryptoCurrency.btc);
        expect(money.amount, equals(BigInt.parse("100000000")));
        expect(money.currency.decimals, equals(8));
        expect(money.toStringWithSymbol(useBaseUnit: true), "100000000 sats");
      });

      group("withSymbolPrefix", () {
        test("with fractionalDigits and padded with zeros", () {
          final money = Money.parse("1", CryptoCurrency.btc);
          expect(money.amount, equals(BigInt.parse("100000000")));
          expect(money.currency.decimals, equals(8));
          expect(
            money.toStringWithSymbol(fractionalDigits: 5, trimZeros: false, withSymbolPrefix: true),
            "BTC 1.00000",
          );
        });

        test("using base unit sats", () {
          final money = Money.parse("1", CryptoCurrency.btc);
          expect(money.amount, equals(BigInt.parse("100000000")));
          expect(money.currency.decimals, equals(8));
          expect(
            money.toStringWithSymbol(useBaseUnit: true, withSymbolPrefix: true),
            "sats 100000000",
          );
        });
      });
    });

    group("different scales", () {
      final coarseOne = Money(BigInt.one, CryptoCurrency.btc, 0);
      final fineOne = Money(BigInt.from(100000000), CryptoCurrency.btc, 8);

      test("== across scales", () {
        expect(coarseOne, equals(fineOne));
        expect(coarseOne, isNot(equals(Money(BigInt.two, CryptoCurrency.btc, 0))));
      });

      test("equal values across scales hash equally", () {
        expect(coarseOne.hashCode, equals(fineOne.hashCode));

        expect(
          Money(BigInt.from(-11), CryptoCurrency.btc, 1).hashCode,
          equals(Money(BigInt.from(-110000000), CryptoCurrency.btc, 8).hashCode),
        );
      });

      test("zero hashes equally at every scale", () {
        final hashes = [0, 1, 8, 18, 30]
            .map((s) => Money(BigInt.zero, CryptoCurrency.btc, s).hashCode)
            .toSet();

        expect(hashes, hasLength(1));
      });

      test("whole units are not confused with their digits", () {
        // (100, scale 0) is one hundred, not one: stripping must stop at 0.
        final oneHundred = Money(BigInt.from(100), CryptoCurrency.btc, 0);

        expect(oneHundred, isNot(equals(coarseOne)));
        expect(oneHundred.hashCode, isNot(equals(coarseOne.hashCode)));
      });

      test("Set deduplicates across scales", () {
        expect(
          {
            Money(BigInt.from(11), CryptoCurrency.btc, 1),
            Money(BigInt.from(110000000), CryptoCurrency.btc, 8),
            Money(BigInt.from(1100), CryptoCurrency.btc, 3),
          },
          hasLength(1),
        );
      });

      test("+ aligns operands", () {
        expect(coarseOne + fineOne, equals(Money(BigInt.two, CryptoCurrency.btc, 0)));
        expect(coarseOne + fineOne, equals(fineOne + coarseOne));
      });

      test("- aligns operands", () {
        // Regression: this used to subtract the raw amounts, i.e. 1 - 100000000.
        expect((coarseOne - fineOne).isZero, isTrue);
        expect((fineOne - coarseOne).isZero, isTrue);

        final threeCoarse = Money(BigInt.from(3), CryptoCurrency.btc, 0);
        expect(threeCoarse - fineOne, equals(Money(BigInt.two, CryptoCurrency.btc, 0)));
        expect(threeCoarse - fineOne, equals(-(fineOne - threeCoarse)));
      });

      test("the result keeps the finer scale", () {
        expect((coarseOne + fineOne).decimals, greaterThanOrEqualTo(fineOne.decimals));
      });

      test("sub-unit precision survives a coarse operand", () {
        final oneSatoshi = Money(BigInt.one, CryptoCurrency.btc, 8);

        expect(
          coarseOne + oneSatoshi,
          equals(Money(BigInt.from(100000001), CryptoCurrency.btc, 8)),
        );
      });

      test("comparison operators align", () {
        expect(coarseOne < fineOne, isFalse);
        expect(coarseOne <= fineOne, isTrue);
        expect(coarseOne >= fineOne, isTrue);
        expect(coarseOne > fineOne, isFalse);
        expect(Money(BigInt.two, CryptoCurrency.btc, 0) > fineOne, isTrue);
      });

      test("compareTo aligns and agrees with ==", () {
        expect(coarseOne.compareTo(fineOne), isZero);
        expect(coarseOne.compareTo(fineOne) == 0, equals(coarseOne == fineOne));
        expect(Money(BigInt.two, CryptoCurrency.btc, 0).compareTo(fineOne), isPositive);
        expect(Money(BigInt.zero, CryptoCurrency.btc, 0).compareTo(fineOne), isNegative);
      });
    });
  });
}
