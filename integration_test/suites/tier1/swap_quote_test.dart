import "package:cw_core/wallet_type.dart";
import "package:integration_test/integration_test.dart";

import "../../core/app_launcher.dart";
import "../../flows/onboarding_flows.dart";
import "../../robots/home_page_robot.dart";
import "../../robots/new_dashboard_robot.dart";
import "../../robots/new_swap_page_robot.dart";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  integrationTest("Swap sheet fetches a provider quote, no trade is created", (tester) async {
    final appLauncher = AppLauncher(tester);
    final onboardingFlows = OnboardingFlows(tester);
    final dashboardRobot = NewDashboardRobot(tester);
    final homePageRobot = HomePageRobot(tester);
    final swapRobot = NewSwapPageRobot(tester);

    await appLauncher.launchApp(testKey: "swap_quote_test_app_key");

    await onboardingFlows.restoreFirstWalletFromSeed(WalletType.solana);

    await dashboardRobot.isDisplayed();
    await homePageRobot.isDisplayed();

    await homePageRobot.openSwapSheet();
    await swapRobot.isDisplayed();

    await swapRobot.enterDepositAmount("1");

    await swapRobot.confirmQuoteReceived();

    await swapRobot.dismissModal();
    await homePageRobot.isDisplayed();
  });
}
