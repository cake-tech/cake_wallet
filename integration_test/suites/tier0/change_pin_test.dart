import "package:cake_wallet/routes.dart";
import "package:cake_wallet/src/screens/wallet_keys/wallet_keys_page.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";

import "../../core/app_launcher.dart";
import "../../core/test_config.dart";
import "../../flows/auth_flows.dart";
import "../../flows/onboarding_flows.dart";
import "../../robots/home_page_robot.dart";
import "../../robots/new_dashboard_robot.dart";
import "../../robots/new_settings_page_robot.dart";
import "../../robots/security_backup_page_robot.dart";
import "../../robots/setup_pin_code_robot.dart";
import "../../robots/wallet_keys_robot.dart";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  integrationTest("Changing the pin replaces the one that unlocks the wallet", (tester) async {
    final appLauncher = AppLauncher(tester);
    final onboardingFlows = OnboardingFlows(tester);
    final authFlows = AuthFlows(tester);
    final dashboardRobot = NewDashboardRobot(tester);
    final homePageRobot = HomePageRobot(tester);
    final settingsRobot = NewSettingsPageRobot(tester);
    final securityRobot = SecurityBackupPageRobot(tester);
    final setupPinRobot = SetupPinCodeRobot(tester);
    final walletKeysRobot = WalletKeysAndSeedPageRobot(tester);

    final newPin = [1, 2, 3, 4];

    expect(newPin, isNot(TestConfig.pin), reason: "The new pin has to differ from the old one");

    await appLauncher.launchApp(testKey: "change_pin_test_app_key");

    await onboardingFlows.createFirstWallet(WalletType.solana);

    await dashboardRobot.isDisplayed();
    await homePageRobot.isDisplayed();

    await homePageRobot.openSettingsSheet();
    await settingsRobot.isDisplayed();

    await settingsRobot.openRow(Routes.securityBackupPage);
    await securityRobot.isDisplayed();

    // Changing the pin asks for the current one first, so a stranger holding the phone cannot
    // lock the owner out of it.
    await securityRobot.openChangePin();
    await authFlows.authenticateWithPin();

    await setupPinRobot.isDisplayed();
    await setupPinRobot.enterPinCode(newPin);
    await setupPinRobot.enterPinCode(newPin);
    await setupPinRobot.tapSuccessButton();

    await securityRobot.isDisplayed();

    // The only thing that proves the change took is the new pin opening something the old one
    // used to guard.
    await securityRobot.goBack();
    await settingsRobot.isDisplayed();

    await settingsRobot.openRow(Routes.showKeys);
    await authFlows.authenticateWithPin(pin: newPin);

    await walletKeysRobot.isDisplayed();

    expect(find.byType(WalletKeysPage), findsOneWidget);
  });
}
