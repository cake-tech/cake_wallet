import 'package:cake_wallet/core/amount_parsing_proxy.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/bitcoin_amount_display_mode.dart';
import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/new_primary_button.dart';
import 'package:cake_wallet/new-ui/widgets/swap_page/swap_confirm_sheet.dart';
import 'package:cake_wallet/new-ui/widgets/swap_page/swap_send_external_modal.dart';
import 'package:cake_wallet/router.dart' as router;
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/exchange_trade/exchange_trade_external_send_page.dart';
import 'package:cake_wallet/view_model/exchange/exchange_trade_view_model.dart';
import 'package:cake_wallet/view_model/exchange/exchange_view_model.dart';
import 'package:cake_wallet/view_model/send/send_view_model.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class ExchangeMock extends Mock implements ExchangeViewModel {}

class TradeMock extends Mock implements ExchangeTradeViewModel {}

class SendMock extends Mock implements SendViewModel {}

class TestStrings extends LocalizationsDelegate<S> {
  const TestStrings();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<S> load(Locale locale) => SynchronousFuture(const S());
  @override
  bool shouldReload(TestStrings old) => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    S.current = const S();
  });
  tearDown(() async {
    await getIt.reset();
  });

  Trade order(ExchangeProviderDescription provider) => Trade(
      id: 'order',
      amount: '1',
      provider: provider,
      from: CryptoCurrency.eth,
      to: CryptoCurrency.xmr,
      inputAddress: 'deposit',
      payoutAddress: 'recipient');

  test('actual named route rejects Pegaroute and reuses the checked other-provider model', () {
    final model = TradeMock();
    Trade trade = order(ExchangeProviderDescription.pegaRoute);
    when(() => model.trade).thenAnswer((_) => trade);
    var resolutions = 0;
    getIt.registerFactory<ExchangeTradeViewModel>(() {
      resolutions++;
      return model;
    });
    expect(
        () => router.createRoute(const RouteSettings(name: Routes.exchangeTradeExternalSendPage)),
        throwsStateError);
    trade = order(ExchangeProviderDescription.changeNow);
    final route =
        router.createRoute(const RouteSettings(name: Routes.exchangeTradeExternalSendPage))
            as MaterialPageRoute<void>;
    final page = route.builder(_Context()) as ExchangeTradeExternalSendPage;
    expect(page.exchangeTradeViewModel, same(model));
    expect(resolutions, 2);
  });

  testWidgets('actual confirmation action is hidden for Pegaroute external mode', (tester) async {
    final exchange = ExchangeMock();
    final model = TradeMock();
    final send = SendMock();
    when(() => model.trade).thenReturn(order(ExchangeProviderDescription.pegaRoute));
    when(() => model.sendViewModel).thenReturn(send);
    when(() => exchange.isSendFromExternal).thenReturn(true);
    when(() => exchange.depositCurrency).thenReturn(CryptoCurrency.eth);
    when(() => exchange.receiveCurrency).thenReturn(CryptoCurrency.xmr);
    when(() => exchange.amountParsingProxy)
        .thenReturn(const AmountParsingProxy(BitcoinAmountDisplayMode.bitcoin));
    await tester.pumpWidget(MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('en')],
        localizationsDelegates: const [TestStrings()],
        home: Scaffold(
            body: SingleChildScrollView(
                child: SwapTransactionDetails(
                    exchangeViewModel: exchange,
                    exchangeTradeViewModel: model,
                    receiveAmount: '0.9')))));
    await tester.pumpAndSettle();
    expect(find.byType(NewPrimaryButton), findsNothing);
    expect(find.byType(SwapSendExternalModal), findsNothing);
  });

  testWidgets('external action rechecks bound trade at tap; no silent Cake payment',
      (tester) async {
    final exchange = ExchangeMock();
    final model = TradeMock();
    final send = SendMock();
    Trade trade = order(ExchangeProviderDescription.changeNow);
    when(() => model.trade).thenAnswer((_) => trade);
    when(() => model.sendViewModel).thenReturn(send);
    when(() => exchange.isSendFromExternal).thenReturn(true);
    when(() => exchange.depositCurrency).thenReturn(CryptoCurrency.eth);
    when(() => exchange.receiveCurrency).thenReturn(CryptoCurrency.xmr);
    when(() => exchange.amountParsingProxy)
        .thenReturn(const AmountParsingProxy(BitcoinAmountDisplayMode.bitcoin));
    await tester.pumpWidget(MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('en')],
        localizationsDelegates: const [TestStrings()],
        home: Scaffold(
            body: SingleChildScrollView(
                child: SwapTransactionDetails(
                    exchangeViewModel: exchange,
                    exchangeTradeViewModel: model,
                    receiveAmount: '0.9')))));
    await tester.pumpAndSettle();
    expect(find.byType(NewPrimaryButton), findsOneWidget);
    trade = order(ExchangeProviderDescription.pegaRoute);
    final button = tester.widget<NewPrimaryButton>(find.byType(NewPrimaryButton));
    button.onPressed();
    await tester.pumpAndSettle();
    expect(find.byType(SwapSendExternalModal), findsNothing);
    verifyNever(() => model.confirmSending());
  });
}

class _Context extends Mock implements BuildContext {}
