import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../components/common_test_constants.dart';
import '../components/common_test_flows.dart';
import '../robots/dashboard_page_robot.dart';
import '../robots/send_page_robot.dart';
import 'package:cake_wallet/.secrets.g.dart' as secrets;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  SendPageRobot sendPageRobot;
  CommonTestFlows commonTestFlows;
  DashboardPageRobot dashboardPageRobot;

  testWidgets('Send flow', (tester) async {
    commonTestFlows = CommonTestFlows(tester);
    sendPageRobot = SendPageRobot(tester: tester);
    dashboardPageRobot = DashboardPageRobot(tester);

    await commonTestFlows.startAppFlow(ValueKey('send_test_app_key'));
    await commonTestFlows.welcomePageToRestoreWalletThroughSeedsFlow(
      CommonTestConstants.testWalletType,
      secrets.solanaTestWalletSeeds,
      CommonTestConstants.pin,
    );
    await dashboardPageRobot.navigateToSendPage();

    await sendPageRobot.enterReceiveAddress(CommonTestConstants.testWalletAddress);
    await sendPageRobot.selectReceiveCurrency(CommonTestConstants.testReceiveCurrency);
    await sendPageRobot.enterAmount(CommonTestConstants.sendTestAmount);
    await sendPageRobot.selectTransactionPriority();

    await sendPageRobot.onSendButtonPressed();

    await sendPageRobot.handleSendResult();

    await sendPageRobot.onSendButtonOnConfirmSendingDialogPressed();

    await sendPageRobot.onSentDialogPopUp();
  });
}
