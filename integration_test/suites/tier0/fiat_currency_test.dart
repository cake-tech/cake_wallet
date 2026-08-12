import "package:cake_wallet/di.dart";
import "package:cake_wallet/entities/fiat_api_mode.dart";
import "package:cake_wallet/entities/fiat_currency.dart";
import "package:cake_wallet/routes.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";

import "../../core/app_launcher.dart";
import "../../flows/onboarding_flows.dart";
import "../../robots/connection_sync_page_robot.dart";
import "../../robots/display_settings_page_robot.dart";
import "../../robots/home_page_robot.dart";
import "../../robots/new_dashboard_robot.dart";
import "../../robots/new_settings_page_robot.dart";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  integrationTest("Turning the fiat api off hides the currency setting, turning it on returns it",
      (tester) async {
    final appLauncher = AppLauncher(tester);
    final onboardingFlows = OnboardingFlows(tester);
    final dashboardRobot = NewDashboardRobot(tester);
    final homePageRobot = HomePageRobot(tester);
    final settingsRobot = NewSettingsPageRobot(tester);
    final connectionRobot = ConnectionSyncPageRobot(tester);
    final displayRobot = DisplaySettingsPageRobot(tester);

    const wanted = FiatCurrency.eur;

    await appLauncher.launchApp(testKey: "fiat_currency_test_app_key");

    await onboardingFlows.createFirstWallet(WalletType.solana);

    await dashboardRobot.isDisplayed();
    await homePageRobot.isDisplayed();

    final settingsStore = getIt.get<SettingsStore>();

    expect(
      settingsStore.fiatCurrency,
      isNot(wanted),
      reason: "The wallet already starts on $wanted, so changing to it would prove nothing",
    );

    await homePageRobot.openSettingsSheet();
    await settingsRobot.isDisplayed();

    if (settingsStore.fiatApiMode != FiatApiMode.disabled) {
      await settingsRobot.openRow(Routes.connectionSync);
      await connectionRobot.isDisplayed();

      await connectionRobot.setFiatApiMode(FiatApiMode.disabled);
      connectionRobot.hasFiatApiMode(FiatApiMode.disabled);

      expect(settingsStore.fiatApiMode, FiatApiMode.disabled);

      await connectionRobot.goBack();
      await settingsRobot.isDisplayed();
    }

    await settingsRobot.openRow(Routes.displaySettingsPage);
    await displayRobot.isDisplayed();

    expect(
      displayRobot.hasFiatCurrencyRow(),
      false,
      reason: "The currency setting is still showing while the fiat api is off",
    );

    await displayRobot.goBack();
    await settingsRobot.isDisplayed();

    await settingsRobot.openRow(Routes.connectionSync);
    await connectionRobot.isDisplayed();

    await connectionRobot.setFiatApiMode(FiatApiMode.enabled);
    connectionRobot.hasFiatApiMode(FiatApiMode.enabled);

    expect(settingsStore.fiatApiMode, FiatApiMode.enabled);

    await connectionRobot.goBack();
    await settingsRobot.isDisplayed();

    await settingsRobot.openRow(Routes.displaySettingsPage);
    await displayRobot.isDisplayed();

    expect(
      displayRobot.hasFiatCurrencyRow(),
      true,
      reason: "The currency setting did not come back after the fiat api was turned on",
    );

    await displayRobot.openFiatCurrencyPicker();
    await displayRobot.chooseFiatCurrency(wanted);

    displayRobot.expectFiatCurrencyShown(wanted);

    expect(
      settingsStore.fiatCurrency,
      wanted,
      reason: "The row shows ${wanted.title} but the setting behind it did not change",
    );
  });
}
