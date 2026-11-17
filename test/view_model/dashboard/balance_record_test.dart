import "package:cake_wallet/entities/fiat_currency.dart";
import "package:cake_wallet/view_model/dashboard/balance_view_model.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/balance.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter_test/flutter_test.dart";

class _ZeroBalance extends Balance {
  _ZeroBalance() : super(Money.zero(CryptoCurrency.btc), Money.zero(CryptoCurrency.btc));
}

BalanceRecord _record({
  required String fiat,
  String secondFiat = "0.00",
  FiatCurrency? fiatCurrency = FiatCurrency.usd,
  String? languageCode,
}) =>
    BalanceRecord(
      raw: _ZeroBalance(),
      availableBalance: "",
      additionalBalance: "",
      secondAvailableBalance: "",
      secondAdditionalBalance: "",
      frozenBalance: "",
      fiatAvailableBalanceRaw: fiat,
      fiatAdditionalBalanceRaw: fiat,
      fiatFrozenBalanceRaw: fiat,
      fiatSecondAvailableBalanceRaw: secondFiat,
      fiatSecondAdditionalBalanceRaw: secondFiat,
      asset: CryptoCurrency.btc,
      secondAsset: CryptoCurrency.btc,
      fiatCurrency: fiatCurrency,
      formattedAssetTitle: "BTC",
      languageCode: languageCode,
    );

void main() {
  group("BalanceRecord fiat balances", () {
    test("carry the currency sign in front of the amount", () {
      final record = _record(fiat: "1234.56", secondFiat: "7.00", languageCode: "en");

      expect(record.fiatAvailableBalance, r"$1,234.56");
      expect(record.fiatAdditionalBalance, r"$1,234.56");
      expect(record.fiatFrozenBalance, r"$1,234.56");
      expect(record.fiatSecondAvailableBalance, r"$7.00");
      expect(record.fiatSecondAdditionalBalance, r"$7.00");
    });

    test("use the app language's separators for the amount", () {
      expect(_record(fiat: "1234.56", languageCode: "de").fiatAvailableBalance, r"$1.234,56");
      expect(
        _record(fiat: "1234.56", fiatCurrency: FiatCurrency.sek, languageCode: "de")
            .fiatAvailableBalance,
        "SEK 1.234,56",
      );
    });

    test("add the second balance into the combined total", () {
      final record = _record(fiat: "1000.50", secondFiat: "234.06", languageCode: "en");

      expect(record.combinedFiatAvailableBalance, r"$1,234.56");
    });

    test("keep a hidden amount hidden", () {
      expect(_record(fiat: "●●●●●").fiatAvailableBalance, r"$●●●●●");
    });

    test("are empty when fiat is turned off", () {
      final record = _record(fiat: "1234.56", fiatCurrency: null, languageCode: "en");

      expect(record.fiatAvailableBalance, "");
      expect(record.combinedFiatAvailableBalance, "");
    });
  });
}
