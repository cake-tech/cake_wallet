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
import "../robots/new_swap_page_robot.dart";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  integrationTest("Create a real swap and broadcast its deposit", (tester) async {
    final appLauncher = AppLauncher(tester);
    final onboardingFlows = OnboardingFlows(tester);
    final authFlows = AuthFlows(tester);
    final dashboardRobot = NewDashboardRobot(tester);
    final homePageRobot = HomePageRobot(tester);
    final sendRobot = NewSendPageRobot(tester);
    final swapRobot = NewSwapPageRobot(tester);

    if (!TestConfig.shouldRunFundsFlow("swap")) {
      tester.printToConsole("FLOWS excludes swap, skipping");
      return;
    }

    final walletTypes = TestConfig.fundedWalletTypesUnderTest;

    expect(walletTypes.isNotEmpty, true, reason: "No funded wallet seeds configured");

    // The swap deposits from the first funded chain, its balance has to cover the
    // provider minimum plus fees.
    final type = walletTypes.first;

    await appLauncher.launchApp(testKey: "swap_funds_test_app_key");

    await onboardingFlows.restoreFirstWalletFromSeed(
      type,
      seed: TestWallets.fundedSeedFor(type),
    );

    await dashboardRobot.isDisplayed();
    await homePageRobot.isDisplayed();

    final appStore = getIt.get<AppStore>();
    expect(appStore.wallet?.type, type);

    final funded = await homePageRobot.pumpUntil(
      () => appStore.wallet?.balance.values.any((b) => b.available.sign > 0) ?? false,
      timeout: const Duration(minutes: 5),
    );

    expect(funded, true, reason: "No spendable balance appeared within 5 minutes");

    await homePageRobot.openSwapSheet();
    await swapRobot.isDisplayed();

    await swapRobot.enterMinimumViableDepositAmount();
    await swapRobot.confirmQuoteReceived();

    await swapRobot.tapSwapButton();

    await authFlows.authenticateWithPinIfPrompted();

    await swapRobot.confirmTradeCreated();

    // The confirm sheet reuses the send swiper for the internal deposit transaction.
    await sendRobot.swipeToConfirm();
    await swapRobot.confirmDepositCommitted();

    await swapRobot.dismissModal();
    await homePageRobot.isDisplayed();

    tester.printToConsole("FUNDS_SWAP_OK: ${type.name}");
  });
}
