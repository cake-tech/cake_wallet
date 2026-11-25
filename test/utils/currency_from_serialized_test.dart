import "package:cake_wallet/entities/fiat_currency.dart";
import "package:cake_wallet/utils/currency_from_serialized.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  group("currencyFromSerialized", () {
    test("round trips a currency with a dot in its title", () async {
      expect(CryptoCurrency.usdcEPoly.serialized, "crypto^USDC.E^POL");
      expect(
        await currencyFromSerialized(CryptoCurrency.usdcEPoly.serialized),
        CryptoCurrency.usdcEPoly,
      );
    });

    test("round trips native and tagged currencies", () async {
      for (final currency in [CryptoCurrency.btc, CryptoCurrency.xmr, CryptoCurrency.usdt]) {
        expect(await currencyFromSerialized(currency.serialized), currency);
      }
    });

    test("round trips fiat", () async {
      expect(await currencyFromSerialized(FiatCurrency.usd.serialized), FiatCurrency.usd);
    });

    test("still reads the old dot separated format", () async {
      expect(await currencyFromSerialized("crypto.BTC"), CryptoCurrency.btc);
      expect(await currencyFromSerialized("crypto.USDT.ETH"), CryptoCurrency.usdterc20);
      expect(await currencyFromSerialized("fiat.USD"), FiatCurrency.usd);
    });
  });

  group("moneyFromSerialized", () {
    test("round trips", () async {
      final money = Money.parse("12.5", CryptoCurrency.usdcEPoly);

      final parsed = await moneyFromSerialized(money.serialized);

      expect(parsed.currency, CryptoCurrency.usdcEPoly);
      expect(parsed.amount, money.amount);
    });

    test("still reads the old dot separated format", () async {
      final parsed = await moneyFromSerialized("crypto.BTC:150000000");

      expect(parsed.currency, CryptoCurrency.btc);
      expect(parsed.amount, BigInt.from(150000000));
    });
  });
}
