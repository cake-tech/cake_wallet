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
  /// - Displays the transaction history progressively as synchronizing happens
  testWidgets('Transaction history flow', (tester) async {
    commonTestFlows = CommonTestFlows(tester);
    dashboardPageRobot = DashboardPageRobot(tester);
    transactionsPageRobot = TransactionsPageRobot(tester);

    await commonTestFlows.startAppFlow(
      ValueKey('confirm_creds_display_correctly_flow_app_key'),
    );

    /// Test Scenario 1 - Displays transaction history list after fully synchronizing.
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

    await transactionsPageRobot.confirmTransactionHistoryListDisplaysCorrectly(false);

    /// Test Scenario 2 - Displays transaction history list while synchronizing.
    ///
    /// For bitcoin/Monero/Wownero WalletTypes.
    await commonTestFlows.switchToWalletMenuFromDashboardPage();

    await commonTestFlows.restoreWalletFromWalletMenu(
      WalletType.bitcoin,
      secrets.bitcoinTestWalletSeeds,
    );

    await dashboardPageRobot.confirmWalletTypeIsDisplayedCorrectly(WalletType.bitcoin);

    await dashboardPageRobot.swipeDashboardTab(true);

    await transactionsPageRobot.isTransactionsPage();

    await transactionsPageRobot.confirmTransactionsPageConstantsDisplayProperly();

    await transactionsPageRobot.confirmTransactionHistoryListDisplaysCorrectly(true);
  });
}
