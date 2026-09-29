import 'package:cake_wallet/exchange/limits.dart';
import 'package:cake_wallet/exchange/provider/pegaroute_exchange_provider.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/pages/swap_page.dart';
import 'package:cake_wallet/new-ui/widgets/swap_page/swap_limit_popup.dart';
import 'package:cake_wallet/view_model/exchange/exchange_view_model.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobx/mobx.dart' show Observable, runInAction;
import 'package:mocktail/mocktail.dart';

class PreviewExchange extends Mock implements ExchangeViewModel {}

void main() {
  testWidgets('an empty comparison shows unavailable, then retry can show Pegaroute', (tester) async {
    final model = PreviewExchange();
    final unavailable = Observable(false);
    final recovered = Observable(false);
    final provider = PegaRouteExchangeProvider();
    var retries = 0;
    when(() => model.isFixedRateMode).thenReturn(false);
    when(() => model.depositAmount).thenReturn('0.01');
    when(() => model.forcedProvider).thenReturn(null);
    when(() => model.providerDisplay).thenAnswer((_) => recovered.value ? provider : null);
    when(() => model.bestRate).thenAnswer((_) => recovered.value ? 2500 : 0);
    when(() => model.noProviderForPair).thenAnswer((_) => unavailable.value);
    when(() => model.depositCurrency).thenReturn(CryptoCurrency.eth);
    when(() => model.receiveCurrency).thenReturn(CryptoCurrency.usdc);
    when(() => model.calculateBestRate()).thenAnswer((_) async {
      retries++;
      runInAction(() {
        unavailable.value = false;
        recovered.value = true;
      });
    });
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'), supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: [S.delegate],
      home: Scaffold(body: SwapProviderPreview(exchangeViewModel: model)),
    ));
    await tester.pump();
    expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
    runInAction(() => unavailable.value = true);
    await tester.pump();
    expect(find.text(S.current.no_providers_available), findsOneWidget);
    expect(find.byType(CupertinoActivityIndicator), findsNothing);
    await tester.tap(find.text(S.current.try_again));
    await tester.pumpAndSettle();
    expect(retries, 1);
    expect(find.text('Pegaroute'), findsOneWidget);
    expect(find.text(S.current.no_providers_available), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the existing minimum popup follows current quote limits', (tester) async {
    final model = PreviewExchange();
    final limits = Observable(Limits(min: 0.0063, max: null));
    when(() => model.hasDepositAmount).thenReturn(true);
    when(() => model.depositAmountCanonical).thenReturn('0.001');
    when(() => model.depositCurrency).thenReturn(CryptoCurrency.eth);
    when(() => model.limits).thenAnswer((_) => limits.value);
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'), supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: [S.delegate],
      home: Scaffold(body: SwapLimitPopup(exchangeViewModel: model)),
    ));
    await tester.pumpAndSettle();
    expect(find.text('${S.current.enter_greater_than} 0.0063 ETH'), findsOneWidget);
    expect(tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity, 1);
    runInAction(() => limits.value = Limits(min: 0, max: null));
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the provider icon has a compiled asset', (tester) async {
    final bytes = await rootBundle.load('${PegaRouteExchangeProvider().description.image}.vec');
    expect(bytes.lengthInBytes, greaterThan(0));
  });
}
