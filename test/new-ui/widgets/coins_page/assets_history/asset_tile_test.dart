import "package:cake_wallet/entities/fiat_currency.dart";
import "package:cake_wallet/new-ui/widgets/coins_page/assets_history/asset_tile.dart";
import "package:cake_wallet/view_model/dashboard/balance_view_model.dart";
import "package:cw_core/balance.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/transaction_history.dart";
import "package:cw_core/transaction_info.dart";
import "package:cw_core/wallet_base.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mobx/mobx.dart";
import "package:mocktail/mocktail.dart";

String ltr(String amount) => "\u2066$amount\u2069";

class _MockWallet extends Mock
    implements WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo> {}

class _MockBalance extends Mock implements Balance {}

void main() {
  testWidgets("redraws the fiat value when the currency format changes", (tester) async {
    final showsIsoCode = Observable(false);
    FiatCurrency.showsIsoCode = () => showsIsoCode.value;
    addTearDown(() => FiatCurrency.showsIsoCode = () => false);
    const asset = CryptoCurrency(title: "TST", name: "tst", decimals: 8);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AssetTile(
            balance: BalanceRecord(
              raw: _MockBalance(),
              availableBalance: "1",
              additionalBalance: "0",
              secondAvailableBalance: "0",
              secondAdditionalBalance: "0",
              frozenBalance: "0",
              fiatAvailableBalanceRaw: "12.34",
              fiatAdditionalBalanceRaw: "0",
              fiatFrozenBalanceRaw: "0",
              fiatSecondAvailableBalanceRaw: "0",
              fiatSecondAdditionalBalanceRaw: "0",
              asset: asset,
              secondAsset: asset,
              fiatCurrency: FiatCurrency.usd,
              formattedAssetTitle: "TST",
            ),
            chainIconPath: "",
            wallet: _MockWallet(),
            showSwap: false,
            isFirst: true,
            isLast: true,
          ),
        ),
      ),
    );

    expect(find.text(ltr(r"$12.34")), findsOneWidget);

    runInAction(() => showsIsoCode.value = true);
    await tester.pump();

    expect(find.text(ltr("USD 12.34")), findsOneWidget);
  });
}
