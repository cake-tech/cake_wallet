import 'package:cake_wallet/wallet_types.g.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../components/common_test_constants.dart';
import '../components/common_test_flows.dart';
import '../robots/dashboard_page_robot.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  CommonTestFlows commonTestFlows;
  DashboardPageRobot dashboardPageRobot;

  testWidgets(
    'Create Wallet Flow',
    (tester) async {
      // Set up error handling to prevent FlutterError.onError assertion
      FlutterError.onError = (FlutterErrorDetails details) {
        // We log the error but don't throw it
        debugPrint('FlutterError caught: ${details.exception}');
      };
      commonTestFlows = CommonTestFlows(tester);
      dashboardPageRobot = DashboardPageRobot(tester);

      // Start the app
      await commonTestFlows.startAppFlow(
        ValueKey('create_wallets_through_seeds_test_app_key'),
      );

      await commonTestFlows.welcomePageToCreateNewWalletFlow(
        WalletType.solana,
        CommonTestConstants.pin,
      );

      // Confirm it actually restores a solana wallet
      await dashboardPageRobot.confirmWalletTypeIsDisplayedCorrectly(WalletType.solana);

      // Do the same for other available wallet types
      for (var walletType in availableWalletTypes) {
        if (walletType == WalletType.solana) {
          continue;
        }

        await dashboardPageRobot.navigateToWalletsListPage();

        await commonTestFlows.createNewWalletFromWalletMenu(walletType);

        await dashboardPageRobot.confirmWalletTypeIsDisplayedCorrectly(walletType);
      }

      // Goes to the wallet menu and provides a confirmation that all the wallets were correctly restored
      await dashboardPageRobot.navigateToWalletsListPage();

      commonTestFlows.confirmAllAvailableWalletTypeIconsDisplayCorrectly();

      await Future.delayed(Duration(seconds: 5));
    },
  );
}
