import "package:cake_wallet/core/auth_service.dart";
import "package:cake_wallet/di.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/locales/locale.dart";
import "package:cake_wallet/new-ui/pages/account_customizer.dart";
import "package:cake_wallet/new-ui/pages/settings_page.dart";
import "package:cake_wallet/routes.dart";
import "package:cake_wallet/view_model/dashboard/balance_view_model.dart";
import "package:cake_wallet/view_model/dashboard/dashboard_view_model.dart";
import "package:cake_wallet/view_model/monero_account_list/account_list_item.dart";
import "package:cake_wallet/view_model/monero_account_list/monero_account_list_view_model.dart";
import "package:cw_core/balance.dart";
import "package:cw_core/transaction_history.dart";
import "package:cw_core/transaction_info.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mocktail/mocktail.dart";

class MockBalanceViewModel extends Mock implements BalanceViewModel {}

class MockDashboardViewModel extends Mock implements DashboardViewModel {}

class _MockAccountListViewModel extends Mock implements MoneroAccountListViewModel {}

class _MockAuthService extends Mock implements AuthService {}

class _MockWallet extends Mock
    implements WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo> {}

void main() {
  late MockBalanceViewModel balanceViewModel;
  late MockDashboardViewModel dashboardViewModel;

  setUpAll(() => S.delegate.load(const Locale("en")));

  setUp(() {
    balanceViewModel = MockBalanceViewModel();
    dashboardViewModel = MockDashboardViewModel();
    when(() => dashboardViewModel.balanceViewModel).thenReturn(balanceViewModel);
  });

  SettingsListItem accountsItem() => SettingsSectionData.walletSettings.items.singleWhere(
        (item) => item.route == Routes.accountCustomizer,
      );

  test("Accounts is the first Wallet Settings item and routes with the dashboard", () {
    final item = accountsItem();

    expect(SettingsSectionData.walletSettings.items.first, same(item));
    expect(item.iconPath, "assets/new-ui/settings_row_icons/accounts.svg");
    expect(item.title, S.current.accounts);
    expect(item.route, Routes.accountCustomizer);
    expect(item.routeArgs, isNull);
    expect(item.routeArgsBuilder, isNotNull);
    expect(item.routeArgsBuilder!(dashboardViewModel), same(dashboardViewModel));
  });

  test("Accounts visibility follows account support", () {
    final item = accountsItem();

    when(() => balanceViewModel.hasAccounts).thenReturn(true);
    expect(item.condition(dashboardViewModel), isTrue);

    when(() => balanceViewModel.hasAccounts).thenReturn(false);
    expect(item.condition(dashboardViewModel), isFalse);
  });

  testWidgets("Accounts opens through the settings modal with the active dashboard",
      (tester) async {
    final accountListViewModel = _MockAccountListViewModel();
    final authService = _MockAuthService();
    final wallet = _MockWallet();
    DashboardViewModel? routedDashboardViewModel;

    when(() => balanceViewModel.hasAccounts).thenReturn(true);
    when(() => dashboardViewModel.hasLightning).thenReturn(false);
    when(() => dashboardViewModel.hasWalletConnect).thenReturn(false);
    when(() => dashboardViewModel.wallet).thenReturn(wallet);
    when(() => dashboardViewModel.loadCardDesigns()).thenAnswer((_) async {});
    when(() => wallet.type).thenReturn(WalletType.wownero);
    when(() => wallet.hardwareWalletType).thenReturn(null);
    when(() => accountListViewModel.accounts).thenReturn(const []);
    when(() => accountListViewModel.selected).thenReturn(
      AccountListItem(label: "Primary", id: 0, isSelected: true),
    );

    getIt.pushNewScope(scopeName: "settings-accounts-route-test");
    getIt.registerFactoryParam<AccountCustomizer, DashboardViewModel, void>(
      (routedViewModel, _) {
        routedDashboardViewModel = routedViewModel;
        return AccountCustomizer(
          accountListViewModel: accountListViewModel,
          dashboardViewModel: routedViewModel,
        );
      },
    );

    try {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: localizationDelegates,
          supportedLocales: S.delegate.supportedLocales,
          home: NewSettingsPage(
            dashboardViewModel: dashboardViewModel,
            authService: authService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(S.current.accounts));
      await tester.pumpAndSettle();

      expect(routedDashboardViewModel, same(dashboardViewModel));
      expect(find.byType(AccountCustomizer), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await getIt.popScope();
    }
  });
}
