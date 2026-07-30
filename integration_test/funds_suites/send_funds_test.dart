import "package:cake_wallet/di.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";

import "../core/app_launcher.dart";
import "../core/test_config.dart";
import "../core/test_wallets.dart";
import "../flows/auth_flows.dart";
import "../flows/onboarding_flows.dart";
import "../robots/home_page_robot.dart";
import "../robots/new_dashboard_robot.dart";
import "../robots/new_send_page_robot.dart";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  integrationTest("Send a real self transaction on every funded chain", (tester) async {
    final appLauncher = AppLauncher(tester);
    final onboardingFlows = OnboardingFlows(tester);
    final authFlows = AuthFlows(tester);
    final dashboardRobot = NewDashboardRobot(tester);
    final homePageRobot = HomePageRobot(tester);
    final sendRobot = NewSendPageRobot(tester);

    if (!TestConfig.shouldRunFundsFlow("send")) {
      tester.printToConsole("FLOWS excludes send, skipping");
      return;
    }

    final walletTypes = TestConfig.fundedWalletTypesUnderTest;

    // A green run that sent nothing proves nothing, missing seeds must be loud.
    expect(walletTypes.isNotEmpty, true, reason: "No funded wallet seeds configured");

    await appLauncher.launchApp(testKey: "send_funds_test_app_key");

    final appStore = getIt.get<AppStore>();
    final failures = <String>[];

    for (final type in walletTypes) {
      tester.printToConsole("Funds send starting for ${type.name}");

      try {
        if (type == walletTypes.first) {
          await onboardingFlows.restoreFirstWalletFromSeed(
            type,
            seed: TestWallets.fundedSeedFor(type),
          );
        } else {
          await dashboardRobot.openWalletsTab();
          await onboardingFlows.restoreAdditionalWalletFromWalletList(
            type,
            seed: TestWallets.fundedSeedFor(type),
          );
        }

        await dashboardRobot.isDisplayed();
        await homePageRobot.isDisplayed();

        expect(appStore.wallet?.type, type);

        // The spendable balance only shows up once the wallet synced far enough.
        final funded = await homePageRobot.pumpUntil(
          () => appStore.wallet?.balance.values.any((b) => b.available.sign > 0) ?? false,
          timeout: const Duration(minutes: 5),
        );

        if (!funded) {
          failures.add("${type.name}: no spendable balance appeared within 5 minutes");
          continue;
        }

        // A self send keeps the funds inside the funded wallet, only fees are spent.
        final ownAddress = appStore.wallet!.walletAddresses.address;

        await homePageRobot.openSendSheet();
        await sendRobot.isDisplayed();

        await sendRobot.enterAddress(ownAddress);
        await sendRobot.enterAmount(TestConfig.fundsSendAmountFor(type));
        await sendRobot.tapSendButton();

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
          // Recovery is best effort, the per chain failure is already recorded.
          tester.printToConsole("Recovery for ${type.name} failed: $e");
        }
      }
    }

    expect(failures, isEmpty, reason: "Failed chains:\n${failures.join("\n")}");
  });
}
