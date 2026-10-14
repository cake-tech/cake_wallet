import "package:cake_wallet/di.dart";
import "package:cake_wallet/routes.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";

import "../../core/app_launcher.dart";
import "../../flows/auth_flows.dart";
import "../../flows/onboarding_flows.dart";
import "../../robots/home_page_robot.dart";
import "../../robots/new_dashboard_robot.dart";
import "../../robots/new_settings_page_robot.dart";
import "../../robots/show_keys_disclaimer_page_robot.dart";
import "../../robots/wallet_keys_robot.dart";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  integrationTest("Displayed seed and keys match the opened wallet", (tester) async {
    final appLauncher = AppLauncher(tester);
    final onboardingFlows = OnboardingFlows(tester);
    final authFlows = AuthFlows(tester);
    final dashboardRobot = NewDashboardRobot(tester);
    final homePageRobot = HomePageRobot(tester);
    final settingsRobot = NewSettingsPageRobot(tester);
    final walletKeysRobot = WalletKeysAndSeedPageRobot(tester);
    final disclaimerRobot = ShowKeysDisclaimerPageRobot(tester);

    // These three cover the different key display paths on the wallet keys page.
    final walletTypes = [WalletType.solana, WalletType.bitcoin, WalletType.monero];

    await appLauncher.launchApp(testKey: "seed_confirmation_test_app_key");

    await onboardingFlows.createFirstWallet(walletTypes.first);

    await dashboardRobot.isDisplayed();
    await homePageRobot.isDisplayed();

    final appStore = getIt.get<AppStore>();

    for (final type in walletTypes) {
      if (type != walletTypes.first) {
        await dashboardRobot.openWalletsTab();
        await onboardingFlows.createAdditionalWalletFromWalletList(type);
        await homePageRobot.isDisplayed();
      }

      expect(appStore.wallet?.type, type);

      tester.printToConsole("Confirming displayed credentials for ${type.name}");

      await homePageRobot.openSettingsSheet();
      await settingsRobot.isDisplayed();

      await settingsRobot.openRow(Routes.showKeysDisclaimer);
      await disclaimerRobot.isDisplayed();
      await disclaimerRobot.tapShowKeys();
      await authFlows.authenticateWithPin();

      await walletKeysRobot.isDisplayed();
      await walletKeysRobot.confirmWalletCredentials(type);

      await settingsRobot.goBack();
      await settingsRobot.dismissModal();

      await homePageRobot.isDisplayed();
    }
  });
}
