import "package:cake_wallet/new-ui/pages/about_page.dart";
import "package:cake_wallet/routes.dart";
import "package:cake_wallet/src/screens/settings/connection_sync_page.dart";
import "package:cake_wallet/src/screens/settings/display_settings_page.dart";
import "package:cake_wallet/src/screens/settings/manage_nodes_page.dart";
import "package:cake_wallet/src/screens/settings/other_settings_page.dart";
import "package:cake_wallet/src/screens/settings/privacy_page.dart";
import "package:cake_wallet/src/screens/settings/security_backup_page.dart";
import "package:cw_core/wallet_type.dart";
import "package:integration_test/integration_test.dart";

import "../../core/app_launcher.dart";
import "../../flows/onboarding_flows.dart";
import "../../robots/home_page_robot.dart";
import "../../robots/new_dashboard_robot.dart";
import "../../robots/new_settings_page_robot.dart";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  integrationTest("Every settings row opens its page and backs out", (tester) async {
    final appLauncher = AppLauncher(tester);
    final onboardingFlows = OnboardingFlows(tester);
    final dashboardRobot = NewDashboardRobot(tester);
    final homePageRobot = HomePageRobot(tester);
    final settingsRobot = NewSettingsPageRobot(tester);

    final rowsUnderTest = <String, Type>{
      Routes.manageNodes: ManageNodesPage,
      Routes.privacyPage: PrivacyPage,
      Routes.otherSettingsPage: OtherSettingsPage,
      Routes.connectionSync: ConnectionSyncPage,
      Routes.displaySettingsPage: DisplaySettingsPage,
      Routes.securityBackupPage: SecurityBackupPage,
      Routes.aboutPage: AboutPage,
    };

    await appLauncher.launchApp(testKey: "settings_nav_test_app_key");

    await onboardingFlows.createFirstWallet(WalletType.solana);

    await dashboardRobot.isDisplayed();
    await homePageRobot.isDisplayed();

    await homePageRobot.openSettingsSheet();
    await settingsRobot.isDisplayed();

    for (final entry in rowsUnderTest.entries) {
      tester.printToConsole("Opening settings row ${entry.key}");

      await settingsRobot.openRow(entry.key);
      await settingsRobot.confirmLeafPageDisplayed(entry.value);

      await settingsRobot.goBack();
      await settingsRobot.isDisplayed();
    }

    await settingsRobot.dismissModal();
    await homePageRobot.isDisplayed();
  });
}
