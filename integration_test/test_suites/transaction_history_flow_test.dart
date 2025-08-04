import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../components/common_test_constants.dart';
import '../components/common_test_flows.dart';
import '../robots/dashboard_page_robot.dart';
import '../robots/transactions_page_robot.dart';
import 'package:cake_wallet/.secrets.g.dart' as secrets;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  CommonTestFlows commonTestFlows;
  DashboardPageRobot dashboardPageRobot;
  TransactionsPageRobot transactionsPageRobot;

  /// Two Test Scenarios
  ///  - Fully Synchronizes and display the transaction history either immediately or few seconds after fully synchronizing
  ///  - Displays the transaction history progressively as synchronizing happens
  testWidgets('Transaction history flow', (tester) async {
    FlutterError.onError = (FlutterErrorDetails details) {
      debugPrint('FlutterError caught: ${details.exception}');
    };

    commonTestFlows = CommonTestFlows(tester);
    dashboardPageRobot = DashboardPageRobot(tester);
    transactionsPageRobot = TransactionsPageRobot(tester);

    await commonTestFlows.startAppFlow(
      ValueKey('confirm_creds_display_correctly_flow_app_key'),
    );

    /// Test Scenario 1 - Displays transaction history list while synchronizing.
    ///
    /// For Solana/Tron WalletTypes.
    await commonTestFlows.welcomePageToRestoreWalletThroughSeedsFlow(
      WalletType.solana,
      secrets.solanaTestWalletSeeds,
      CommonTestConstants.pin,
    );

    await dashboardPageRobot.confirmWalletTypeIsDisplayedCorrectly(WalletType.solana);

    await dashboardPageRobot.swipeDashboardTab(true);

    await transactionsPageRobot.isTransactionsPage();

    await transactionsPageRobot.confirmTransactionsPageConstantsDisplayProperly();

    // Wait time for the first scenario to ensure proper loading
    await tester.pump(Duration(seconds: 3));
    await tester.pumpAndSettle();

    await transactionsPageRobot.confirmTransactionHistoryListDisplaysCorrectly(true);

    /// Test Scenario 2 - Displays transaction history list after fully synchronizing.
    ///
    /// For Bitcoin/Monero/Wownero WalletTypes.
    await dashboardPageRobot.navigateToWalletsListPage();

    await commonTestFlows.restoreWalletFromWalletMenu(
      WalletType.bitcoin,
      secrets.bitcoinTestWalletSeeds,
    );

    await dashboardPageRobot.confirmWalletTypeIsDisplayedCorrectly(WalletType.bitcoin);

    await dashboardPageRobot.swipeDashboardTab(true);

    await transactionsPageRobot.isTransactionsPage();

    await transactionsPageRobot.confirmTransactionsPageConstantsDisplayProperly();

    // Wait time for the second scenario to ensure proper loading
    await tester.pump(Duration(seconds: 3));
    await tester.pumpAndSettle();

    await transactionsPageRobot.confirmTransactionHistoryListDisplaysCorrectly(false);
  });
}
