import "package:cake_wallet/routes.dart";
import "package:cake_wallet/src/screens/wallet_keys/wallet_keys_page.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";

import "../../core/app_launcher.dart";
import "../../flows/auth_flows.dart";
import "../../flows/onboarding_flows.dart";
import "../../robots/home_page_robot.dart";
import "../../robots/new_dashboard_robot.dart";
import "../../robots/new_settings_page_robot.dart";
import "../../robots/wallet_keys_robot.dart";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  integrationTest("Seed and keys page rejects a wrong pin and accepts the right one", (tester) async {
    final appLauncher = AppLauncher(tester);
    final onboardingFlows = OnboardingFlows(tester);
    final authFlows = AuthFlows(tester);
    final dashboardRobot = NewDashboardRobot(tester);
    final homePageRobot = HomePageRobot(tester);
    final settingsRobot = NewSettingsPageRobot(tester);
    final walletKeysRobot = WalletKeysAndSeedPageRobot(tester);

    final wrongPin = [9, 9, 9, 9];

    await appLauncher.launchApp(testKey: "show_keys_auth_test_app_key");

    await onboardingFlows.createFirstWallet(WalletType.solana);

    await dashboardRobot.isDisplayed();
    await homePageRobot.isDisplayed();

    await homePageRobot.openSettingsSheet();
    await settingsRobot.isDisplayed();

    // The seed and keys row always re-authenticates regardless of the pin timeout window.
    await settingsRobot.openRow(Routes.showKeys);

    await authFlows.authenticateWithPin(pin: wrongPin);

    // A wrong pin must keep the keys page locked away.
    await settingsRobot.settle(max: const Duration(seconds: 3));
    expect(find.byType(WalletKeysPage), findsNothing);
    expect(authFlows.isPinWidgetShown(), true);

    await authFlows.authenticateWithPin();

    await walletKeysRobot.isWalletKeysAndSeedPage();

    await settingsRobot.goBack();
    await settingsRobot.dismissModal();
    await homePageRobot.isDisplayed();
  });
}
