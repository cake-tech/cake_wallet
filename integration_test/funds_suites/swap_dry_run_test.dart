import "package:cake_wallet/di.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";

import "../core/app_launcher.dart";
import "../core/test_config.dart";
import "../flows/funds_flows.dart";
import "../robots/home_page_robot.dart";
import "../robots/new_swap_page_robot.dart";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Deliberately stops before the swap button. Creating a trade registers an order with the
  // provider, which is a side effect that outlives the test even though no funds move, so
  // this goes as far as a live quote against a wallet that could actually cover it and then
  // walks away. swap_funds_test is the one that commits.
  integrationTest("Swap prices a real deposit without creating a trade", (tester) async {
    final appLauncher = AppLauncher(tester);
    final fundsFlows = FundsFlows(tester);
    final homePageRobot = HomePageRobot(tester);
    final swapRobot = NewSwapPageRobot(tester);

    if (!TestConfig.shouldDryRun("swap")) {
      tester.printToConsole("FLOWS excludes swap, skipping");
      return;
    }

    final walletTypes = TestConfig.fundedWalletTypesUnderTest;

    expect(walletTypes.isNotEmpty, true, reason: "No funded wallet seeds configured");

    await appLauncher.launchApp(testKey: "swap_dry_run_test_app_key");

    final appStore = getIt.get<AppStore>();

    // The deposit comes off the first funded chain, the same one swap_funds_test uses, so a
    // quote here is evidence that suite would have something to spend.
    final type = walletTypes.first;

    final opened = await fundsFlows.openFundedWallet(type);

    expect(opened, true, reason: "Every funded wallet for ${type.name} came up empty");
    expect(appStore.wallet?.type, type);

    await homePageRobot.openSwapSheet();
    await swapRobot.isDisplayed();

    await swapRobot.enterMinimumViableDepositAmount();

    await swapRobot.confirmQuoteReceived();

    tester.printToConsole("${type.name} received a quote, no trade created");

    await swapRobot.dismissModal();
    await homePageRobot.isDisplayed();
  });
}
