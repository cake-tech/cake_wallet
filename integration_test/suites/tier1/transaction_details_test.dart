import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";

import "../../core/app_launcher.dart";
import "../../flows/onboarding_flows.dart";
import "../../robots/home_page_robot.dart";
import "../../robots/new_dashboard_robot.dart";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  integrationTest("Tapping a transaction opens the details of that transaction", (tester) async {
    final appLauncher = AppLauncher(tester);
    final onboardingFlows = OnboardingFlows(tester);
    final dashboardRobot = NewDashboardRobot(tester);
    final homePageRobot = HomePageRobot(tester);

    await appLauncher.launchApp(testKey: "transaction_details_test_app_key");

    await onboardingFlows.restoreFirstWalletFromSeed(WalletType.solana);

    await dashboardRobot.isDisplayed();
    await homePageRobot.isDisplayed();

    await homePageRobot.confirmTransactionHistoryVisible();

    await homePageRobot.openAllTransactions();
    await homePageRobot.confirmAllTransactionsVisible();

    final tapped = homePageRobot.firstTransactionIdInAllView();

    expect(tapped, isNotEmpty, reason: "The tile carries no transaction id to check against");

    await homePageRobot.openFirstTransactionDetails();

    // A list that hands the wrong transaction to the details screen shows one person's
    // amounts under another's id, and nothing on the screen would say so.
    expect(
      homePageRobot.openedTransactionId(),
      tapped,
      reason: "The details opened for a different transaction than the one tapped",
    );

    homePageRobot.hasTransactionIdRow();
  });
}
