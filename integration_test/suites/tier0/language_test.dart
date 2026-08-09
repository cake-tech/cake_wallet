import "package:cake_wallet/routes.dart";
import "package:cw_core/wallet_type.dart";
import "package:integration_test/integration_test.dart";

import "../../core/app_launcher.dart";
import "../../flows/onboarding_flows.dart";
import "../../robots/display_settings_page_robot.dart";
import "../../robots/home_page_robot.dart";
import "../../robots/new_dashboard_robot.dart";
import "../../robots/new_settings_page_robot.dart";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  integrationTest("Changing the language changes what the settings screen shows",
      (tester) async {
    final appLauncher = AppLauncher(tester);
    final onboardingFlows = OnboardingFlows(tester);
    final dashboardRobot = NewDashboardRobot(tester);
    final homePageRobot = HomePageRobot(tester);
    final settingsRobot = NewSettingsPageRobot(tester);
    final displayRobot = DisplaySettingsPageRobot(tester);

    // Not the default, so seeing it afterwards means the change took rather than the screen
    // having always said so.
    const languageCode = "de";
    const languageName = "Deutsch (German)";

    await appLauncher.launchApp(testKey: "fiat_currency_test_app_key");

    await onboardingFlows.createFirstWallet(WalletType.solana);

    await dashboardRobot.isDisplayed();
    await homePageRobot.isDisplayed();

    await homePageRobot.openSettingsSheet();
    await settingsRobot.isDisplayed();

    await settingsRobot.openRow(Routes.displaySettingsPage);
    await displayRobot.isDisplayed();

    await displayRobot.openLanguagePicker();
    await displayRobot.chooseLanguage(languageCode);

    displayRobot.expectLanguageShown(languageName);
  });
}
