import "package:cake_wallet/di.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";

import "../core/app_launcher.dart";
import "../core/funds_outcome.dart";
import "../core/test_config.dart";
import "../flows/auth_flows.dart";
import "../flows/funds_flows.dart";
import "../robots/home_page_robot.dart";
import "../robots/new_send_page_robot.dart";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  integrationTest("Every funded chain can build a transaction without sending it", (tester) async {
    final appLauncher = AppLauncher(tester);
    final authFlows = AuthFlows(tester);
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
          tester.printToConsole("${type.name} has nothing spendable, top it up");
          FundsOutcome.empty(tester, type.name, "every funded wallet is empty");
          continue;
        }

        expect(appStore.wallet?.type, type);

        final ownAddress = appStore.wallet!.walletAddresses.address;

        await homePageRobot.openSendSheet();
        await sendRobot.isDisplayed();

        await sendRobot.enterAddress(ownAddress);
        await sendRobot.enterAmount(TestConfig.fundsSendAmountFor(type));
        await sendRobot.tapSendButtonWhenReady();

        await authFlows.authenticateWithPin(required: false);

        await sendRobot.confirmTransactionBuilt();

        tester.printToConsole("${type.name} built a transaction, leaving it unsent");
        FundsOutcome.ok(tester, type.name, "built and signed, not broadcast");

        expect(
          await fundsFlows.returnToHome(),
          true,
          reason: "${type.name} finished but the send flow would not close",
        );
      } catch (e) {
        if (FundsOutcome.needsFurtherReview(e.toString())) {
          failures.add("${type.name}: $e");
        } else {
          tester.printToConsole("${type.name} needs attention rather than a fix: $e");
        }

        FundsOutcome.failed(tester, type.name, e.toString());

        if (!await fundsFlows.returnToHome()) {
          // The app is hanging or found itself somewhere we don't know,
          // no need to continue running anything else
          for (final skipped in walletTypes.skip(walletTypes.indexOf(type) + 1)) {
            FundsOutcome.waiting(
              tester,
              skipped.name,
              "never ran, ${type.name} left the app somewhere it could not come back from",
            );
          }

          if (FundsOutcome.needsFurtherReview(e.toString())) {
            failures.add("${type.name}: could not get back to the home page, "
                "the chains after this one never ran");
          }

          break;
        }
      }
    }

    expect(failures, isEmpty, reason: "Failed chains:\n${failures.join("\n")}");
  });
}
