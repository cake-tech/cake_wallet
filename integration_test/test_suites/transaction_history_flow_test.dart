import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../components/common_test_constants.dart';
import '../components/common_test_flows.dart';
import '../robots/auth_page_robot.dart';
import '../robots/dashboard_page_robot.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  AuthPageRobot authPageRobot;
  CommonTestFlows commonTestFlows;
  DashboardPageRobot dashboardPageRobot;

  testWidgets('Transaction history flow', (tester) async {
    authPageRobot = AuthPageRobot(tester);
    commonTestFlows = CommonTestFlows(tester);
    dashboardPageRobot = DashboardPageRobot(tester);

    // Start the app
    await commonTestFlows.startAppFlow(
      ValueKey('confirm_creds_display_correctly_flow_app_key'),
    );

    await commonTestFlows.welcomePageToCreateNewWalletFlow(
      WalletType.solana,
      CommonTestConstants.pin,
    );

    await dashboardPageRobot.confirmWalletTypeIsDisplayedCorrectly(WalletType.solana);

    await dashboardPageRobot.swipeDashboardTab(true);
  });
}
