import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/dashboard/dashboard_page.dart';
import 'package:cake_wallet/src/screens/dashboard/pages/balance/crypto_balance_widget.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter_test/flutter_test.dart';

import '../components/common_test_cases.dart';
import 'dashboard_menu_widget_robot.dart';

class DashboardPageRobot {
  DashboardPageRobot(this.tester)
      : commonTestCases = CommonTestCases(tester),
        dashboardMenuWidgetRobot = DashboardMenuWidgetRobot(tester);

  final WidgetTester tester;
  final DashboardMenuWidgetRobot dashboardMenuWidgetRobot;
  late CommonTestCases commonTestCases;

  Future<void> isDashboardPage() async {
    await commonTestCases.isSpecificPage<DashboardPage>();
    await commonTestCases.takeScreenshots('dashboard_page');
  }

  Future<void> confirmWalletTypeIsDisplayedCorrectly(
    WalletType type, {
    bool isHaven = false,
  }) async {
    final cryptoBalanceWidget =
        tester.widget<CryptoBalanceWidget>(find.byType(CryptoBalanceWidget));
    final hasAccounts = cryptoBalanceWidget.dashboardViewModel.balanceViewModel.hasAccounts;

    if (hasAccounts) {
      final walletName = cryptoBalanceWidget.dashboardViewModel.name;
      commonTestCases.hasText(walletName);
    } else {
      final walletName = walletTypeToString(type);
      final assetName = isHaven ? '$walletName Assets' : walletName;
      commonTestCases.hasText(assetName);
    }
    await commonTestCases.defaultSleepTime(seconds: 5);
  }

  void confirmServiceUpdateButtonDisplays() {
    commonTestCases.hasValueKey('dashboard_page_services_update_button_key');
  }

  void confirmSyncIndicatorButtonDisplays() {
    commonTestCases.hasValueKey('dashboard_page_sync_indicator_button_key');
  }

  void confirmMenuButtonDisplays() {
    commonTestCases.hasValueKey('dashboard_page_wallet_menu_button_key');
  }

  Future<void> confirmRightCryptoAssetTitleDisplaysPerPageView(
    WalletType type, {
    bool isHaven = false,
  }) async {
    //Balance Page
    await confirmWalletTypeIsDisplayedCorrectly(type, isHaven: isHaven);

    // Swipe to Cake features Page
    await swipeDashboardTab(false);
    commonTestCases.hasText('Cake ${S.current.features}');

    // Swipe back to balance
    await swipeDashboardTab(true);

    // Swipe to Transactions Page
    await swipeDashboardTab(true);
    commonTestCases.hasText(S.current.transactions);

    // Swipe back to balance
    await swipeDashboardTab(false);
    await commonTestCases.defaultSleepTime(seconds: 3);
  }

  Future<void> swipeDashboardTab(bool swipeRight) async {
    await commonTestCases.swipeByPageKey(
      key: 'dashboard_page_view_key',
      swipeRight: swipeRight,
    );
    await commonTestCases.defaultSleepTime();
  }

  Future<void> openDrawerMenu() async {
    await commonTestCases.tapItemByKey('dashboard_page_wallet_menu_button_key');
    await commonTestCases.defaultSleepTime();
  }

  Future<void> navigateToBuyPage() async {
    await commonTestCases.tapItemByKey('dashboard_page_buy_action_button_key');
  }

  Future<void> navigateToWalletsListPage({bool isDrawer = false}) async {
    await tester.pumpAndSettle(Duration(milliseconds: 1000));

    await commonTestCases.tapItemByKey(
      isDrawer
          ? 'dashboard_page_menu_widget_wallet_menu_button_key'
          : 'dashboard_page__wallet_list_button_key',
    );

    await tester.pumpAndSettle(Duration(milliseconds: 2000));
  }

  Future<void> navigateToSendPage() async {
    await commonTestCases.tapItemByKey('dashboard_page_send_action_button_key');
  }

  Future<void> navigateToSellPage() async {
    await commonTestCases.tapItemByKey('dashboard_page_sell_action_button_key');
  }

  Future<void> navigateToReceivePage() async {
    await commonTestCases.tapItemByKey('dashboard_page_receive_action_button_key');
  }

  Future<void> navigateToExchangePage() async {
    await commonTestCases.tapItemByKey('dashboard_page_swap_action_button_key');
  }
}
