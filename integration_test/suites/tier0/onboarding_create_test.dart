import "package:cake_wallet/di.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";

import "../../core/app_launcher.dart";
import "../../core/test_config.dart";
import "../../flows/onboarding_flows.dart";
import "../../robots/home_page_robot.dart";
import "../../robots/new_dashboard_robot.dart";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  integrationTest("Create a wallet for each configured wallet type", (tester) async {
    final appLauncher = AppLauncher(tester);
    final onboardingFlows = OnboardingFlows(tester);
    final dashboardRobot = NewDashboardRobot(tester);
    final homePageRobot = HomePageRobot(tester);

    await appLauncher.launchApp(testKey: "onboarding_create_test_app_key");

    final walletTypes = TestConfig.walletTypesUnderTest;
    final firstType = walletTypes.first;

    tester.printToConsole("Creating first wallet: ${firstType.name}");

    await onboardingFlows.createFirstWallet(firstType);

    await dashboardRobot.isDisplayed();
    await homePageRobot.isDisplayed();

    final appStore = getIt.get<AppStore>();
    expect(appStore.wallet?.type, firstType);

    await homePageRobot.hasWalletName(appStore.wallet!.name);

    for (final type in walletTypes.skip(1)) {
      tester.printToConsole("Creating additional wallet: ${type.name}");

      await dashboardRobot.openWalletsTab();

      await onboardingFlows.createAdditionalWalletFromWalletList(type);

      await dashboardRobot.isDisplayed();
      await homePageRobot.isDisplayed();

      expect(appStore.wallet?.type, type);

      await homePageRobot.hasWalletName(appStore.wallet!.name);
    }
  });
}
