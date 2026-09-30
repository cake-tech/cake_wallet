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

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  integrationTest("A 25 word monero seed restores through the legacy path", (tester) async {
    final appLauncher = AppLauncher(tester);
    final onboardingFlows = OnboardingFlows(tester);
    final dashboardRobot = NewDashboardRobot(tester);
    final homePageRobot = HomePageRobot(tester);

    final legacySeed = TestWallets.moneroLegacySeed;

    expect(
      legacySeed.split(" ").length,
      25,
      reason: "The legacy seed secret is not a 25 word seed, this suite would restore a polyseed",
    );

    await appLauncher.launchApp(testKey: "monero_legacy_seed_test_app_key");

    await onboardingFlows.restoreFirstWalletFromSeed(WalletType.monero, seed: legacySeed);

    await dashboardRobot.isDisplayed();
    await homePageRobot.isDisplayed();

    final appStore = getIt.get<AppStore>();

    expect(appStore.wallet?.type, WalletType.monero);

    expect(
      appStore.wallet?.seed?.split(" ").length,
      25,
      reason: "The wallet came back with a seed of a different length than the one restored",
    );
  });
}
