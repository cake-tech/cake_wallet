import "package:cake_wallet/di.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";

import "../../core/app_launcher.dart";
import "../../core/test_wallets.dart";
import "../../flows/onboarding_flows.dart";
import "../../robots/home_page_robot.dart";
import "../../robots/new_dashboard_robot.dart";
import "../../robots/restore_from_seed_or_key_robot.dart";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  integrationTest("A seed the wallet cannot parse restores nothing", (tester) async {
    final appLauncher = AppLauncher(tester);
    final onboardingFlows = OnboardingFlows(tester);
    final restoreRobot = RestoreFromSeedOrKeysPageRobot(tester);
    final dashboardRobot = NewDashboardRobot(tester);
    final homePageRobot = HomePageRobot(tester);

    const walletType = WalletType.solana;

    await appLauncher.launchApp(testKey: "invalid_seed_test_app_key");

    await onboardingFlows.startRestoringFirstWallet(walletType);

    // Twelve words that are not in the wordlist. Restoring from this would either fail
    // outright or, worse, derive some other wallet the user has no keys for.
    await restoreRobot.enterSeedPhraseForWalletRestore(
      "alpha bravo charlie delta echo foxtrot golf hotel india juliet kilo lima",
    );

    await restoreRobot.onRestoreWalletButtonPressed();

    await restoreRobot.expectRestoreRefused();

    // The same form with the real seed goes through. Without this the test above would pass
    // just as happily if the form were broken and restored nothing for any seed at all.
    await restoreRobot.selectWalletNameFromAvailableOptions();
    await restoreRobot.enterSeedPhraseForWalletRestore(TestWallets.seedFor(walletType));
    await restoreRobot.onRestoreWalletButtonPressed();

    await dashboardRobot.isDisplayed();
    await homePageRobot.isDisplayed();

    expect(getIt.get<AppStore>().wallet?.type, walletType);
  });
}
