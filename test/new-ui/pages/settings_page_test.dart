import "package:cake_wallet/core/auth_service.dart";
import "package:cake_wallet/di.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/locales/locale.dart";
import "package:cake_wallet/new-ui/pages/account_customizer.dart";
import "package:cake_wallet/new-ui/pages/settings_page.dart";
import "package:cake_wallet/new-ui/widgets/modern_button.dart";
import "package:cake_wallet/routes.dart";
import "package:cake_wallet/view_model/dashboard/balance_view_model.dart";
import "package:cake_wallet/view_model/dashboard/dashboard_view_model.dart";
import "package:cake_wallet/view_model/monero_account_list/monero_account_list_view_model.dart";
import "package:cw_core/balance.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/db/sqlite.dart" as sqlite;
import "package:cw_core/transaction_history.dart";
import "package:cw_core/transaction_info.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mocktail/mocktail.dart";
import "package:sqflite/sqflite.dart";

class MockBalanceViewModel extends Mock implements BalanceViewModel {}

class MockDashboardViewModel extends Mock implements DashboardViewModel {}

class _MockAccountListViewModel extends Mock implements MoneroAccountListViewModel {}

class _MockAuthService extends Mock implements AuthService {}

class _MockDatabase extends Mock implements Database {}

class _MockWallet extends Mock
    implements WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo> {}

class _MockWalletInfo extends Mock implements WalletInfo {}

void main() {
  late S english;
  late S french;
  late S portuguese;
  late MockBalanceViewModel balanceViewModel;
  late MockDashboardViewModel dashboardViewModel;
  late _MockWallet wallet;
  late _MockAuthService authService;

  setUpAll(() async {
    english = await S.delegate.load(const Locale("en"));
    french = await S.delegate.load(const Locale("fr"));
    portuguese = await S.delegate.load(const Locale("pt"));
    await S.delegate.load(const Locale("en"));
  });

  setUp(() {
    balanceViewModel = MockBalanceViewModel();
    dashboardViewModel = MockDashboardViewModel();
    wallet = _MockWallet();
    authService = _MockAuthService();

    when(() => dashboardViewModel.balanceViewModel).thenReturn(balanceViewModel);
    when(() => dashboardViewModel.wallet).thenReturn(wallet);
    when(() => wallet.name).thenReturn("My Cake Wallet");
    when(() => wallet.hardwareWalletType).thenReturn(null);
  });

  Widget settingsApp({Locale locale = const Locale("en")}) => MaterialApp(
        locale: locale,
        localizationsDelegates: localizationDelegates,
        supportedLocales: S.delegate.supportedLocales,
        home: NewSettingsPage(
          dashboardViewModel: dashboardViewModel,
          authService: authService,
        ),
      );

  test("wallet resolver handles every WalletType and always includes Nodes", () {
    const resolver = WalletSettingsResolver();

    for (final type in WalletType.values) {
      expect(
        resolver.settingsFor(type),
        contains(WalletSettingsItemType.nodes),
        reason: "$type must explicitly expose node settings",
      );
    }

    expect(
      resolver.settingsFor(WalletType.bitcoin),
      containsAll([
        WalletSettingsItemType.coinControl,
        WalletSettingsItemType.lightningUsername,
        WalletSettingsItemType.silentPayments,
      ]),
    );
    expect(
      resolver.settingsFor(WalletType.litecoin),
      containsAll([
        WalletSettingsItemType.coinControl,
        WalletSettingsItemType.mweb,
      ]),
    );
    expect(
      resolver.settingsFor(WalletType.monero),
      containsAll([
        WalletSettingsItemType.accounts,
        WalletSettingsItemType.coinControl,
        WalletSettingsItemType.resyncDevice,
      ]),
    );
    expect(
      resolver.settingsFor(WalletType.ethereum),
      contains(WalletSettingsItemType.walletConnect),
    );
  });

  test("app settings expose only implemented destinations in the Figma order", () {
    final section = const SettingsPageSectionsResolver().appSettings(english);

    expect(section.title, english.app_settings);
    expect(
      section.items.map((item) => item.route),
      [
        Routes.connectionSync,
        Routes.displaySettingsPage,
        Routes.securityBackupPage,
        Routes.backup,
      ],
    );
  });

  test("runtime wallet capabilities filter supported Bitcoin settings", () {
    when(() => wallet.type).thenReturn(WalletType.bitcoin);
    when(() => balanceViewModel.hasAccounts).thenReturn(false);
    when(() => dashboardViewModel.hasLightning).thenReturn(true);
    when(() => dashboardViewModel.hasSilentPayments).thenReturn(false);

    final sections = const WalletSettingsResolver().resolveSections(
      english,
      dashboardViewModel,
    );
    final routes = sections.expand((section) => section).map((item) => item.route);

    expect(routes, contains(Routes.manageNodes));
    expect(routes, contains(Routes.unspentCoinsList));
    expect(routes, contains(Routes.lightningUsernamePage));
    expect(routes, isNot(contains(Routes.accountCustomizer)));
    expect(routes, isNot(contains(Routes.silentPaymentsSettings)));
  });

  testWidgets("main Settings shows the active wallet and wallet-general/app groups",
      (tester) async {
    when(() => wallet.type).thenReturn(WalletType.wownero);

    await tester.pumpWidget(settingsApp());
    await tester.pumpAndSettle();

    expect(find.text("My Cake Wallet"), findsOneWidget);
    expect(find.text("Wownero ${english.settings_title}"), findsOneWidget);
    expect(find.text(english.privacy), findsOneWidget);
    expect(find.text(english.seed_and_keys), findsOneWidget);
    expect(find.text(english.other), findsOneWidget);
    expect(find.text(english.app_settings), findsOneWidget);
    expect(find.text(english.connections), findsOneWidget);
    expect(find.text(english.display), findsOneWidget);
    expect(find.text(english.security), findsOneWidget);
    expect(find.text(english.backup), findsOneWidget);
    expect(find.text(english.accounts), findsNothing);
    expect(find.text(english.nodes), findsNothing);
  });

  testWidgets("wallet settings title and rows follow the active Bitcoin capabilities",
      (tester) async {
    when(() => wallet.type).thenReturn(WalletType.bitcoin);
    when(() => balanceViewModel.hasAccounts).thenReturn(false);
    when(() => dashboardViewModel.hasLightning).thenReturn(true);
    when(() => dashboardViewModel.hasSilentPayments).thenReturn(true);

    await tester.pumpWidget(settingsApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text("Bitcoin ${english.settings_title}"));
    await tester.pumpAndSettle();

    expect(find.text("Bitcoin ${english.settings_title}"), findsOneWidget);
    expect(find.text(english.nodes), findsOneWidget);
    expect(find.text(english.coin_control_settings), findsOneWidget);
    expect(find.text("Lightning ${english.username}"), findsOneWidget);
    expect(find.text(english.silent_payments), findsOneWidget);
    expect(find.text(english.accounts), findsNothing);
    expect(find.text(english.privacy), findsNothing);
  });

  testWidgets("long localized wallet settings title stays clear of the back control",
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    when(() => wallet.type).thenReturn(WalletType.bsc);
    when(() => balanceViewModel.hasAccounts).thenReturn(false);
    when(() => dashboardViewModel.hasWalletConnect).thenReturn(false);

    await tester.pumpWidget(settingsApp(locale: const Locale("pt")));
    await tester.pumpAndSettle();

    final title = "BNB Smart Chain ${portuguese.settings_title}";
    await tester.tap(find.text(title));
    await tester.pumpAndSettle();

    final titleFinder = find.text(title);
    final titleText = tester.widget<Text>(titleFinder);
    final backButton = find.byType(ModernButton);
    final titleGroup = find.byKey(ValueKey(title));

    expect(titleText.maxLines, 1);
    expect(titleText.overflow, TextOverflow.ellipsis);
    expect(tester.getRect(titleGroup).left, greaterThanOrEqualTo(tester.getRect(backButton).right));
    expect(tester.getRect(titleGroup).center.dx, 160);
    expect(tester.takeException(), isNull);
  });

  testWidgets("settings labels rebuild when the locale changes", (tester) async {
    when(() => wallet.type).thenReturn(WalletType.wownero);

    await tester.pumpWidget(settingsApp());
    await tester.pumpAndSettle();
    expect(find.text(english.privacy), findsOneWidget);

    await tester.pumpWidget(settingsApp(locale: const Locale("fr")));
    await tester.pumpAndSettle();

    expect(find.text(french.privacy), findsOneWidget);
    if (english.privacy != french.privacy) {
      expect(find.text(english.privacy), findsNothing);
    }
  });

  testWidgets("Accounts opens through nested wallet settings with the active dashboard",
      (tester) async {
    final accountListViewModel = _MockAccountListViewModel();
    final database = _MockDatabase();
    final walletInfo = _MockWalletInfo();
    final originalDatabase = sqlite.db;
    var scopeOpen = false;
    DashboardViewModel? routedDashboardViewModel;

    when(() => balanceViewModel.hasAccounts).thenReturn(true);
    when(() => dashboardViewModel.loadCardDesigns()).thenAnswer((_) async {});
    when(() => wallet.type).thenReturn(WalletType.wownero);
    when(() => wallet.currency).thenReturn(CryptoCurrency.wow);
    when(() => wallet.walletInfo).thenReturn(walletInfo);
    when(() => walletInfo.internalId).thenReturn(42);
    when(() => accountListViewModel.accounts).thenReturn(const []);
    when(
      () => database.query(
        any(),
        where: any(named: "where"),
        whereArgs: any(named: "whereArgs"),
      ),
    ).thenAnswer((_) async => const []);

    try {
      sqlite.db = database;
      getIt.pushNewScope(scopeName: "settings-accounts-route-test");
      scopeOpen = true;
      getIt.registerFactoryParam<AccountCustomizer, DashboardViewModel, void>(
        (routedViewModel, _) {
          routedDashboardViewModel = routedViewModel;
          return AccountCustomizer(
            accountListViewModel: accountListViewModel,
            dashboardViewModel: routedViewModel,
          );
        },
      );

      await tester.pumpWidget(settingsApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text("Wownero ${english.settings_title}"));
      await tester.pumpAndSettle();
      await tester.tap(find.text(english.accounts));
      await tester.pumpAndSettle();

      expect(routedDashboardViewModel, same(dashboardViewModel));
      expect(find.byType(AccountCustomizer), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      if (scopeOpen) {
        await getIt.popScope();
      }
      sqlite.db = originalDatabase;
    }
  });

  test("Bitcoin account copy is explicitly onchain when the capability is available", () {
    when(() => balanceViewModel.hasAccounts).thenReturn(true);
    when(() => wallet.type).thenReturn(WalletType.bitcoin);
    when(() => dashboardViewModel.hasLightning).thenReturn(false);
    when(() => dashboardViewModel.hasSilentPayments).thenReturn(false);

    final accountItem = const WalletSettingsResolver()
        .resolveSections(english, dashboardViewModel)
        .expand((section) => section)
        .singleWhere((item) => item.route == Routes.accountCustomizer);

    expect(accountItem.title, english.accounts_onchain);
  });
}
