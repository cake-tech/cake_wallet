import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:cw_core/wallet_type.dart';

import '../components/common_test_constants.dart';
import '../components/common_test_flows.dart';
import '../components/common_test_cases.dart';
import '../robots/dashboard_page_robot.dart';
import '../robots/send_page_robot.dart';
import 'package:cake_wallet/.secrets.g.dart' as secrets;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  SendPageRobot sendPageRobot;
  CommonTestFlows commonTestFlows;
  DashboardPageRobot dashboardPageRobot;
  CommonTestCases commonTestCases;

  testWidgets('Send flow with wallet switching for insufficient balance - testing \$1 send',
      (tester) async {
    FlutterError.onError = (FlutterErrorDetails details) {
      debugPrint('FlutterError caught: ${details.exception}');
    };

    commonTestFlows = CommonTestFlows(tester);
    sendPageRobot = SendPageRobot(tester: tester);
    dashboardPageRobot = DashboardPageRobot(tester);
    commonTestCases = CommonTestCases(tester);

    await commonTestFlows.startAppFlow(ValueKey('send_test_app_key'));

    // Various wallet options we want to use to test the send flow
    final walletConfigs = [
      {
        'type': WalletType.solana,
        'seed': secrets.solanaTestWalletSeeds2,
        'name': 'Solana Wallet 1',
      },
      {
        'type': WalletType.solana,
        'seed': secrets.solanaTestWalletSeeds,
        'name': 'Solana Wallet 2',
      },
      {
        'type': WalletType.ethereum,
        'seed': secrets.ethereumTestWalletSeeds,
        'name': 'Ethereum Wallet',
      },
    ];

    bool hasSufficientBalance = false;
    WalletType? successfulWalletType;

    // We try each wallet configuration until we find one with sufficient balance
    for (int i = 0; i < walletConfigs.length; i++) {
      final config = walletConfigs[i];

      if ((config['seed'] as String).isEmpty) {
        tester.printToConsole('Skipping ${config['name']}, seed is empty');
        continue;
      }

      tester.printToConsole('Trying ${config['name']}');

      // For first wallet, we restore wallet afresh, for subsequent ones, we do a wallet switch
      if (i == 0) {
        await commonTestFlows.welcomePageToRestoreWalletThroughSeedsFlow(
          config['type'] as WalletType,
          config['seed'] as String,
          CommonTestConstants.pin,
        );
      } else {
        await commonTestCases.goBack();
        await commonTestCases.defaultSleepTime();

        await dashboardPageRobot.navigateToWalletsListPage();
        await commonTestCases.defaultSleepTime();

        await commonTestFlows.restoreWalletFromWalletMenu(
          config['type'] as WalletType,
          config['seed'] as String,
        );
      }

      await dashboardPageRobot.confirmWalletTypeIsDisplayedCorrectly(config['type'] as WalletType);

      // Navigate to send page
      await dashboardPageRobot.navigateToSendPage();
      await sendPageRobot.checkIfSendPageIsVisible();

      await sendPageRobot.enterReceiveAddress(CommonTestConstants.testWalletAddress);
      await sendPageRobot.selectReceiveCurrency(CommonTestConstants.sendTestReceiveCurrency);

      await sendPageRobot.selectTransactionPriority();

      // Main check to see if this wallet has sufficient balance for $1 send
      final hasBalance = await sendPageRobot.validateWalletBalanceForOneDollarSend();
      if (hasBalance) {
        hasSufficientBalance = true;
        successfulWalletType = config['type'] as WalletType;
        tester.printToConsole(
          '${config['name']} has sufficient balance for \$${CommonTestConstants.sendTestFiatAmount} send, proceeding with send',
        );
        break;
      } else {
        tester.printToConsole(
          '${config['name']} has insufficient balance for \$${CommonTestConstants.sendTestFiatAmount} send',
        );
        if (i < walletConfigs.length - 1) {
          tester.printToConsole('Switching to next wallet...');
        }
      }
    }

    // We only proceed with the send if we have sufficient balance
    if (hasSufficientBalance && successfulWalletType != null) {
      tester.printToConsole('Performing send transaction with $successfulWalletType wallet');

      await sendPageRobot.testFiatAmountEntry();
      await sendPageRobot.testCryptoAmountEntry();

      await sendPageRobot.onSendButtonPressed();
      await sendPageRobot.onSendSliderOnConfirmSendingBottomSheetDragged();
      await sendPageRobot.handleTransactionSuccessFlow();
    } else {
      tester.printToConsole(
        'Test completed without sending - all available wallets have insufficient balance for \$${CommonTestConstants.sendTestFiatAmount} send',
      );
    }
  });
}
