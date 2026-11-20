import "package:cake_wallet/exchange/exchange_provider_description.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/exchange_limits.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/provider_rate.dart";
import "package:cake_wallet/utils/list_extension.dart";
import "package:cw_core/amount/exchange_rate.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  ProviderRate btcToXmr(ExchangeProviderDescription provider, String xmrPerBtc) => ProviderRate(
    provider: provider,
    rate: ExchangeRate.fromAmounts(
      Money.parse("1", CryptoCurrency.btc),
      Money.parse(xmrPerBtc, CryptoCurrency.xmr),
    ),
    limits: ExchangeLimits(),
  );

  test("more payout per deposit compares higher", () {
    final better = btcToXmr(ExchangeProviderDescription.changeNow, "251");
    final worse = btcToXmr(ExchangeProviderDescription.trocador, "250");

    expect(better.compareTo(worse), greaterThan(0));
    expect(worse.compareTo(better), lessThan(0));
    expect(better.compareTo(btcToXmr(ExchangeProviderDescription.trocador, "251")), 0);
  });

  test("the best of a set of rates is the one paying out the most", () {
    final rates = [
      btcToXmr(ExchangeProviderDescription.trocador, "249.5"),
      btcToXmr(ExchangeProviderDescription.changeNow, "251"),
      btcToXmr(ExchangeProviderDescription.chainflip, "250"),
    ];

    expect(rates.max.provider, ExchangeProviderDescription.changeNow);
    expect((rates..sort((a, b) => b.compareTo(a))).map((r) => r.provider), [
      ExchangeProviderDescription.changeNow,
      ExchangeProviderDescription.chainflip,
      ExchangeProviderDescription.trocador,
    ]);
  });

  test("rates priced in different directions refuse to compare", () {
    final btcPriced = btcToXmr(ExchangeProviderDescription.changeNow, "250");
    final xmrPriced = ProviderRate(
      provider: ExchangeProviderDescription.trocador,
      rate: ExchangeRate.fromAmounts(
        Money.parse("250", CryptoCurrency.xmr),
        Money.parse("1", CryptoCurrency.btc),
      ),
      limits: ExchangeLimits(),
    );

    expect(() => btcPriced.compareTo(xmrPriced), throwsArgumentError);
  });
}
