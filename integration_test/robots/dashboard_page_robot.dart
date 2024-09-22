import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/dashboard/dashboard_page.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter_test/flutter_test.dart';

import '../components/common_test_cases.dart';

class DashboardPageRobot {
  DashboardPageRobot(this.tester) : commonTestCases = CommonTestCases(tester);

  final WidgetTester tester;
  late CommonTestCases commonTestCases;

  Future<void> isDashboardPage() async {
    await commonTestCases.isSpecificPage<DashboardPage>();
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

  Future<void> confirmRightCryptoAssetTitleDisplaysPerPageView(WalletType type,
      {bool isHaven = false}) async {
    //Balance Page
    final walletName = walletTypeToString(type);
    final assetName = isHaven ? '$walletName Assets' : walletName;
    commonTestCases.hasText(assetName);

    // Swipe to Cake features Page
    await commonTestCases.swipeByPageKey(key: 'dashboard_page_view_key', swipeRight: false);
    await commonTestCases.defaultSleepTime();
    commonTestCases.hasText('Cake ${S.current.features}');

    // Swipe back to balance
    await commonTestCases.swipeByPageKey(key: 'dashboard_page_view_key');
    await commonTestCases.defaultSleepTime();

    // Swipe to Transactions Page
    await commonTestCases.swipeByPageKey(key: 'dashboard_page_view_key');
    await commonTestCases.defaultSleepTime();
    commonTestCases.hasText(S.current.transactions);

    // Swipe back to balance
    await commonTestCases.swipeByPageKey(key: 'dashboard_page_view_key', swipeRight: false);
    await commonTestCases.defaultSleepTime(seconds: 5);
  }

  Future<void> navigateToBuyPage() async {
    await commonTestCases.tapItemByKey('dashboard_page_${S.current.buy}_action_button_key');
  }

  Future<void> navigateToSendPage() async {
    await commonTestCases.tapItemByKey('dashboard_page_${S.current.send}_action_button_key');
  }

  Future<void> navigateToSellPage() async {
    await commonTestCases.tapItemByKey('dashboard_page_${S.current.sell}_action_button_key');
  }

  Future<void> navigateToReceivePage() async {
    await commonTestCases.tapItemByKey('dashboard_page_${S.current.receive}_action_button_key');
  }

  Future<void> navigateToExchangePage() async {
    await commonTestCases.tapItemByKey('dashboard_page_${S.current.exchange}_action_button_key');
  }
}
