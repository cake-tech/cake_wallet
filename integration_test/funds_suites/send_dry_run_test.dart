import "package:cake_wallet/di.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";

import "../core/app_launcher.dart";
import "../core/test_config.dart";
import "../core/test_wallets.dart";
import "../flows/funds_flows.dart";
import "../robots/home_page_robot.dart";
import "../robots/new_send_page_robot.dart";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Everything the send flow does except the swipe
  integrationTest("Every funded chain can build a transaction without sending it", (tester) async {
    final appLauncher = AppLauncher(tester);
    final fundsFlows = FundsFlows(tester);
    final homePageRobot = HomePageRobot(tester);
    final sendRobot = NewSendPageRobot(tester);

    if (!TestConfig.shouldDryRun("send")) {
      tester.printToConsole("FLOWS excludes send, skipping");
      return;
    }

    final walletTypes = TestConfig.fundedWalletTypesUnderTest;

    expect(walletTypes.isNotEmpty, true, reason: "No funded wallet seeds configured");

    await appLauncher.launchApp(testKey: "send_dry_run_test_app_key");

    final appStore = getIt.get<AppStore>();
    final failures = <String>[];

    for (final type in walletTypes) {
      tester.printToConsole("Send dry run starting for ${type.name}");

      try {
        final opened = await fundsFlows.openFundedWallet(type);

        if (!opened) {
          final walletCount = TestWallets.fundedSeedsFor(type).length;
          failures.add("${type.name}: all $walletCount funded wallets are empty, top one up");
          continue;
        }

        expect(appStore.wallet?.type, type);

        final ownAddress = appStore.wallet!.walletAddresses.address;

        await homePageRobot.openSendSheet();
        await sendRobot.isDisplayed();

        await sendRobot.enterAddress(ownAddress);
        await sendRobot.enterAmount(TestConfig.fundsSendAmountFor(type));
        await sendRobot.tapSendButtonWhenReady();

        await sendRobot.confirmTransactionBuilt();

        tester.printToConsole("${type.name} built a transaction, leaving it unsent");

        await sendRobot.dismissModal();
        await homePageRobot.isDisplayed();
      } catch (e) {
        failures.add("${type.name}: $e");

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
