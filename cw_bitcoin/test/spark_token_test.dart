import "package:cw_core/amount/money.dart";
import "package:cw_core/currency_groups.dart";
import "package:cw_bitcoin/lightning/spark_token.dart";
import "package:flutter_test/flutter_test.dart";

SparkToken _usdb({bool enabled = true, String? walletName, Set<String>? groups}) => SparkToken(
      name: "USDB",
      symbol: "USDB",
      tokenIdentifier: "btkn1xgrvjwey5ngcagvap2dzzvsy4uk8ua9x69k82dwvt5e7ef9drm9qztux87",
      decimal: 6,
      enabled: enabled,
      walletName: walletName,
      groups: groups ?? const {CurrencyGroups.stablecoin},
    );

void main() {
  group("Spark token raw amounts", () {
    test("6 decimal token renders raw base units", () {
      final usdb = _usdb();

      expect(Money(BigInt.from(100000), usdb).toStringWithPrecision(), "0.1");
      expect(Money(BigInt.from(931614), usdb).toStringWithPrecision(), "0.931614");
    });

    test("the same raw amount means different values per decimals", () {
      final raw = BigInt.from(100000);

      final six = SparkToken(
        name: "Six",
        symbol: "SIX",
        tokenIdentifier: "btkn1six",
        decimal: 6,
      );
      final zero = SparkToken(
        name: "Zero",
        symbol: "ZERO",
        tokenIdentifier: "btkn1zero",
        decimal: 0,
      );

      expect(Money(raw, six).toStringWithPrecision(), "0.1");
      expect(Money(raw, zero).toStringWithPrecision(), "100000");
    });
  });

  group("Spark token amount parsing", () {
    test("parses fractional amounts for a 6 decimal token", () {
      final usdb = _usdb();

      expect(Money.parse("0.1", usdb).amount, BigInt.from(100000));
      expect(Money.parse("10.339089", usdb).amount, BigInt.from(10339089));
    });

    test("rejects more fractional digits than the token has decimals", () {
      final zero = SparkToken(
        name: "Zero",
        symbol: "ZERO",
        tokenIdentifier: "btkn1zero",
        decimal: 0,
      );

      expect(() => Money.parse("5.5", zero), throwsFormatException);
    });
  });

  group("Spark token identity", () {
    test("equality and hashCode are keyed by tokenIdentifier alone", () {
      final a = _usdb(walletName: "wallet-a");
      final b = _usdb(walletName: "wallet-b", enabled: false);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test("a different tokenIdentifier is a different token even with the same symbol", () {
      final usdb = _usdb();
      final impostor = SparkToken(
        name: "USDB",
        symbol: "USDB",
        tokenIdentifier: "btkn1someotheridentifier",
        decimal: 6,
      );

      expect(usdb, isNot(equals(impostor)));
    });
  });

  group("Spark token serialization", () {
    test("toMap/fromMap round-trips every field", () {
      final usdb = _usdb(walletName: "my wallet");
      usdb.id = 7;

      final restored = SparkToken.fromMap(usdb.toMap());

      expect(restored.name, usdb.name);
      expect(restored.symbol, usdb.symbol);
      expect(restored.tokenIdentifier, usdb.tokenIdentifier);
      expect(restored.decimal, usdb.decimal);
      expect(restored.enabled, usdb.enabled);
      expect(restored.walletName, usdb.walletName);
      expect(restored.id, usdb.id);
      expect(restored.groups, usdb.groups);
    });

    test(
        "groups round-trips through toMap/fromMap - regression for the bug where a "
        "DB-reloaded SparkToken always lost its stablecoin tag", () {
      final usdb = _usdb(groups: const {CurrencyGroups.stablecoin});

      final restored = SparkToken.fromMap(usdb.toMap());

      expect(restored.groups, contains(CurrencyGroups.stablecoin));
    });

    test("fromMap defaults groups to empty when the column is missing or empty", () {
      final missingColumn = _usdb().toMap()..remove("groups");
      expect(SparkToken.fromMap(missingColumn).groups, isEmpty);

      final emptyColumn = _usdb().toMap()..["groups"] = "";
      expect(SparkToken.fromMap(emptyColumn).groups, isEmpty);
    });

    test("fromMap defaults enabled to true when the column is missing", () {
      final map = _usdb().toMap()..remove("enabled");

      expect(SparkToken.fromMap(map).enabled, isTrue);
    });

    test("fromMap tolerates int-encoded booleans from sqflite", () {
      final map = _usdb().toMap()
        ..["enabled"] = 0
        ..["isPotentialScam"] = 1;

      final restored = SparkToken.fromMap(map);
      expect(restored.enabled, isFalse);
      expect(restored.isPotentialScam, isTrue);
    });
  });

  group("Spark token copyWith", () {
    test("preserves identity while overriding presentation fields", () {
      final usdb = _usdb(walletName: "original");
      final copy = SparkToken.copyWith(usdb, walletName: "copied", enabled: false);

      expect(copy.tokenIdentifier, usdb.tokenIdentifier);
      expect(copy.walletName, "copied");
      expect(copy.enabled, isFalse);
      expect(copy, equals(usdb));
    });

    test("defaults to the source token's own enabled/walletName when not overridden", () {
      final usdb = _usdb(enabled: false, walletName: "wallet");
      final copy = SparkToken.copyWith(usdb);

      expect(copy.enabled, isFalse);
      expect(copy.walletName, "wallet");
    });
  });
}
