import "package:cake_wallet/routes.dart";
import "package:cw_core/wallet_type.dart";
import "package:integration_test/integration_test.dart";

import "../../core/app_launcher.dart";
import "../../flows/onboarding_flows.dart";
import "../../robots/home_page_robot.dart";
import "../../robots/new_dashboard_robot.dart";
import "../../robots/new_receive_page_robot.dart";
import "../../robots/new_send_page_robot.dart";
import "../../robots/new_settings_page_robot.dart";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  integrationTest("Release-checklist controls expose their semantics identifiers", (tester) async {
    final onboardingFlows = OnboardingFlows(tester);
    final dashboardRobot = NewDashboardRobot(tester);
    final homePageRobot = HomePageRobot(tester);
    final settingsRobot = NewSettingsPageRobot(tester);
    final receiveRobot = NewReceivePageRobot(tester);
    final sendRobot = NewSendPageRobot(tester);

    await AppLauncher(tester).launchApp(testKey: "semantics_identifiers_test_app_key");
    await onboardingFlows.createFirstWallet(WalletType.solana);

    await dashboardRobot.isDisplayed();
    await homePageRobot.isDisplayed();
    for (final id in [
      "dashboard_page_home_action_button_key",
      "dashboard_page_wallets_action_button_key",
      "home_page_send_button_key",
      "home_page_receive_button_key",
      "home_page_settings_button_key",
    ]) {
      await homePageRobot.expectTestId(id);
    }

    await homePageRobot.openSettingsSheet();
    await settingsRobot.isDisplayed();
    await settingsRobot.expectTestId("settings_page_top_bar_title_key");
    for (final (route, id) in [
      (Routes.privacyPage, "settings_page_privacy_row_key"),
      (Routes.displaySettingsPage, "settings_page_display_settings_row_key"),
    ]) {
      await settingsRobot.scrollUntilRowVisible(route);
      await settingsRobot.expectTestId(id);
    }
    await settingsRobot.dismissModal();
    await homePageRobot.isDisplayed();

    await homePageRobot.openReceiveSheet();
    await receiveRobot.isDisplayed();
    for (final id in [
      "receive_page_top_bar_title_key",
      "receive_page_copy_button_key",
      "receive_page_set_amount_button_key",
    ]) {
      await receiveRobot.expectTestId(id);
    }
    await receiveRobot.tapTestId("receive_page_set_amount_button_key");
    for (final id in [
      "receive_amount_modal_title_key",
      "receive_amount_modal_leading_key",
      "receive_amount_modal_amount_textfield_key",
      "receive_amount_modal_continue_button_key",
    ]) {
      await receiveRobot.expectTestId(id);
    }
    await receiveRobot.enterTextByTestId("receive_amount_modal_amount_textfield_key", "1");
    await receiveRobot.tapTestId("receive_amount_modal_continue_button_key");
    await receiveRobot.isDisplayed();
    await receiveRobot.dismissModal();
    await homePageRobot.isDisplayed();

    await homePageRobot.openSendSheet();
    await sendRobot.isDisplayed();
    for (final id in [
      "send_page_top_bar_title_key",
      "send_page_address_input_key",
      "send_page_amount_input_key",
    ]) {
      await sendRobot.expectTestId(id);
    }
    await sendRobot.dismissModal();
    await homePageRobot.isDisplayed();
  });
}
