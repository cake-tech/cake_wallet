import "package:cake_wallet/di.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";

import "../core/app_launcher.dart";
import "../core/test_config.dart";
import "../core/test_wallets.dart";
import "../flows/auth_flows.dart";
import "../flows/funds_flows.dart";
import "../robots/home_page_robot.dart";
import "../robots/new_send_page_robot.dart";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  integrationTest("Send a real self transaction on every funded chain", (tester) async {
    final appLauncher = AppLauncher(tester);
    final fundsFlows = FundsFlows(tester);
    final authFlows = AuthFlows(tester);
    final homePageRobot = HomePageRobot(tester);
    final sendRobot = NewSendPageRobot(tester);

    if (!TestConfig.shouldSpend("send")) {
      tester.printToConsole("FLOWS excludes send, skipping");
      return;
    }

    final walletTypes = TestConfig.fundedWalletTypesUnderTest;

    expect(walletTypes.isNotEmpty, true, reason: "No funded wallet seeds configured");

    await appLauncher.launchApp(testKey: "send_funds_test_app_key");

    final appStore = getIt.get<AppStore>();
    final failures = <String>[];

    for (final type in walletTypes) {
      tester.printToConsole("Funds send starting for ${type.name}");

      try {
        final opened = await fundsFlows.openFundedWallet(type);

        if (!opened) {
          final walletCount = TestWallets.fundedSeedsFor(type).length;
          failures.add("${type.name}: none of the $walletCount funded wallets has a "
              "spendable balance, top them up before the next run");
          continue;
        }

        expect(appStore.wallet?.type, type);

        // A self send keeps the funds inside the funded wallet, only fees are spent.
        final ownAddress = appStore.wallet!.walletAddresses.address;

        await homePageRobot.openSendSheet();
        await sendRobot.isDisplayed();

        await sendRobot.enterAddress(ownAddress);
        await sendRobot.enterAmount(TestConfig.fundsSendAmountFor(type));
        await sendRobot.tapSendButtonWhenReady();

        await authFlows.authenticateWithPinIfPrompted();

        await sendRobot.swipeToConfirm();
        await sendRobot.confirmTransactionCommitted();

        await sendRobot.dismissModal();
        await homePageRobot.isDisplayed();

        tester.printToConsole("FUNDS_SEND_OK: ${type.name}");
      } catch (e) {
        failures.add("${type.name}: $e");
        tester.printToConsole("FUNDS_SEND_FAIL: ${type.name}: $e");

        try {
          await sendRobot.dismissModal();
          await homePageRobot.isDisplayed();
        } catch (e) {
          tester.printToConsole("Recovery for ${type.name} failed: $e");
        }
      }
    }

    expect(failures, isEmpty, reason: "Failed chains:\n${failures.join("\n")}");
  });
}
