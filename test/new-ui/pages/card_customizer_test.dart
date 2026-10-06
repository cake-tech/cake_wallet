import "dart:async";

import "package:cake_wallet/di.dart";
import "package:cake_wallet/entities/balance_display_mode.dart";
import "package:cake_wallet/entities/bitcoin_amount_display_mode.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/locales/locale.dart";
import "package:cake_wallet/new-ui/pages/card_customizer.dart";
import "package:cake_wallet/new-ui/viewmodels/card_customizer/card_customizer_bloc.dart";
import "package:cake_wallet/new-ui/widgets/coins_page/cards/balance_card.dart";
import "package:cake_wallet/new-ui/widgets/money/money_settings_provider.dart";
import "package:cake_wallet/themes/core/theme_store.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cake_wallet/view_model/dashboard/balance_view_model.dart";
import "package:cake_wallet/view_model/dashboard/dashboard_view_model.dart";
import "package:cake_wallet/view_model/wallet_account_list/account_list_item.dart";
import "package:cake_wallet/view_model/wallet_account_list/monero_account_list/monero_account_list_view_model.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/card_design.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mocktail/mocktail.dart";

class _MockCardCustomizerBloc extends Mock implements CardCustomizerBloc {}

class _MockDashboardViewModel extends Mock implements DashboardViewModel {}

class _MockBalanceViewModel extends Mock implements BalanceViewModel {}

class _MockSettingsStore extends Mock implements SettingsStore {}

class _MockAccountListViewModel extends Mock implements MoneroAccountListViewModel {}

class _RouteTracker {
  bool completed = false;
  bool? result;
}

CardCustomizerState _accountState(String accountName) => CardCustomizerInitial(
      0,
      0,
      const <CardDesign>[CardDesign.gradientOnlyDesign],
      const <Gradient>[CardDesign.gradientBlue],
      accountName,
      0,
      false,
      0,
    );

Future<_RouteTracker> _openCustomizer(
  WidgetTester tester,
  CardCustomizerBloc bloc, {
  required DashboardViewModel dashboardViewModel,
  required MoneroAccountListViewModel accountListViewModel,
  required AccountListItem? account,
}) async {
  final tracker = _RouteTracker();
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: localizationDelegates,
      supportedLocales: S.delegate.supportedLocales,
      builder: (_, child) => MoneySettingsProvider(
        settingsStore: dashboardViewModel.settingsStore,
        child: child!,
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () {
              Navigator.of(context)
                  .push<bool>(
                MaterialPageRoute(
                  builder: (_) => BlocProvider<CardCustomizerBloc>.value(
                    value: bloc,
                    child: Material(
                      child: CardCustomizer(
                        cryptoTitle: "Monero",
                        cryptoName: "xmr",
                        dashboardViewModel: dashboardViewModel,
                        account: account,
                        accountListViewModel: account == null ? null : accountListViewModel,
                      ),
                    ),
                  ),
                ),
              )
                  .then((result) {
                tracker
                  ..completed = true
                  ..result = result;
              });
            },
            child: const Text("Open card customizer"),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text("Open card customizer"));
  await tester.pumpAndSettle();
  return tracker;
}

void main() {
  late _MockCardCustomizerBloc bloc;
  late _MockDashboardViewModel dashboardViewModel;
  late _MockAccountListViewModel accountListViewModel;
  late AccountListItem account;
  late StreamController<CardCustomizerState> stateController;

  setUpAll(() {
    registerFallbackValue(
      AccountListItem(id: -1, label: "fallback", balance: Money.zero(CryptoCurrency.xmr)),
    );
    getIt.registerSingleton(ThemeStore());
  });

  tearDownAll(() async {
    await getIt.unregister<ThemeStore>();
  });

  setUp(() {
    bloc = _MockCardCustomizerBloc();
    dashboardViewModel = _MockDashboardViewModel();
    accountListViewModel = _MockAccountListViewModel();
    account =
        AccountListItem(id: 0, label: "Savings", balance: Money.parse("1.25", CryptoCurrency.xmr));
    final balanceViewModel = _MockBalanceViewModel();
    final settingsStore = _MockSettingsStore();
    when(() => settingsStore.balanceDisplayMode).thenReturn(BalanceDisplayMode.displayableBalance);
    when(() => dashboardViewModel.settingsStore).thenReturn(settingsStore);
    when(() => settingsStore.displayAmountsInSatoshi).thenReturn(BitcoinAmountDisplayMode.bitcoin);
    stateController = StreamController<CardCustomizerState>.broadcast();
    when(() => bloc.stream).thenAnswer((_) => stateController.stream);
    when(() => bloc.canHide).thenReturn(true);
    when(() => dashboardViewModel.balanceViewModel).thenReturn(balanceViewModel);
    when(() => balanceViewModel.accountBalance(any())).thenAnswer(
      (invocation) => (invocation.positionalArguments.single as AccountListItem)
          .balance
          .toStringWithPrecision(),
    );
    when(() => balanceViewModel.accountFiatBalance(any(), currencyPrefix: true))
        .thenReturn("USD 2.50");
    when(() => accountListViewModel.currency).thenReturn(CryptoCurrency.xmr);
    when(() => accountListViewModel.accounts).thenAnswer((_) => [account]);
    when(() => accountListViewModel.fullBalance(any())).thenAnswer((_) => account.balance);
  });

  tearDown(() async {
    await stateController.close();
  });

  testWidgets("account mode renders edit controls and cancels funded archival", (tester) async {
    when(() => bloc.state).thenReturn(_accountState(""));
    final tracker = await _openCustomizer(
      tester,
      bloc,
      dashboardViewModel: dashboardViewModel,
      accountListViewModel: accountListViewModel,
      account: account,
    );

    expect(find.text("Edit Account"), findsOneWidget);
    expect(find.text("#1"), findsOneWidget);
    expect(find.text("Unnamed Account"), findsOneWidget);
    expect(find.text("1.25"), findsOneWidget);
    expect(find.text("USD 2.50"), findsOneWidget);
    expect(find.text("Account name"), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text("Archive Account"), findsOneWidget);
    expect(find.text("This change can be reverted"), findsOneWidget);
    expect(
      tester.getTopLeft(find.byType(BalanceCard).first).dy,
      lessThan(tester.getTopLeft(find.text("Account name")).dy),
    );

    await tester.ensureVisible(find.text("Archive Account"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Archive Account"));
    await tester.pumpAndSettle();

    expect(find.text("Are you sure you want to Archive this account?"), findsOneWidget);
    expect(find.text("This account has the following funds:"), findsOneWidget);
    expect(find.text("1.25 XMR"), findsOneWidget);
    expect(
      find.text("Before proceeding, it is recommended you move them to an account you will use"),
      findsOneWidget,
    );
    expect(
      find.text(
        "Archiving an account does not delete any funds or activity. You can reverse this action",
      ),
      findsOneWidget,
    );

    await tester.tap(find.text("Cancel"));
    await tester.pumpAndSettle();

    expect(find.byType(CardCustomizer), findsOneWidget);
    expect(tracker.completed, isFalse);
  });

  testWidgets("confirming hidden empty-account archival returns true to the parent",
      (tester) async {
    account =
        AccountListItem(id: 0, label: "Savings", balance: Money.parse("0", CryptoCurrency.xmr));
    final settingsStore = dashboardViewModel.settingsStore;
    final balanceViewModel = dashboardViewModel.balanceViewModel;
    when(() => settingsStore.balanceDisplayMode).thenReturn(BalanceDisplayMode.hiddenBalance);
    when(() => balanceViewModel.accountBalance(any())).thenReturn("●●●●●●");
    when(() => balanceViewModel.accountFiatBalance(any(), currencyPrefix: true))
        .thenReturn("USD ●●●●●");
    when(() => bloc.state).thenReturn(_accountState("Savings"));
    final tracker = await _openCustomizer(
      tester,
      bloc,
      dashboardViewModel: dashboardViewModel,
      accountListViewModel: accountListViewModel,
      account: account,
    );

    await tester.ensureVisible(find.text("Archive Account"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Archive Account"));
    await tester.pumpAndSettle();

    expect(find.text("1. Savings"), findsOneWidget);
    expect(find.text("This account has the following funds:"), findsNothing);
    expect(
      find.text(
        "This action won’t delete the account or its past activity, but only hide it inside Cake Wallet",
      ),
      findsOneWidget,
    );
    expect(find.text("You can reverse this action from Accounts settings"), findsOneWidget);

    await tester.tap(find.text("Continue"));
    await tester.pumpAndSettle();

    expect(find.byType(CardCustomizer), findsNothing);
    expect(tracker.completed, isTrue);
    expect(tracker.result, isTrue);
  });

  testWidgets("account editing remains available when archival is disabled", (tester) async {
    when(() => bloc.state).thenReturn(_accountState("Savings"));
    when(() => bloc.canHide).thenReturn(false);

    await _openCustomizer(
      tester,
      bloc,
      dashboardViewModel: dashboardViewModel,
      accountListViewModel: accountListViewModel,
      account: account,
    );

    expect(find.text("Edit Account"), findsOneWidget);
    expect(find.text("Account name"), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text("Savings"), findsWidgets);
    expect(find.text("Archive Account"), findsNothing);
  });

  testWidgets("wallet card editing does not require an account", (tester) async {
    when(() => bloc.state).thenReturn(_accountState(""));
    when(() => bloc.canHide).thenReturn(false);

    await _openCustomizer(
      tester,
      bloc,
      dashboardViewModel: dashboardViewModel,
      accountListViewModel: accountListViewModel,
      account: null,
    );

    expect(find.text("Edit Card"), findsOneWidget);
    expect(find.byType(BalanceCard), findsWidgets);
    expect(find.byType(TextField), findsNothing);
    expect(find.text("Archive Account"), findsNothing);
  });
}
