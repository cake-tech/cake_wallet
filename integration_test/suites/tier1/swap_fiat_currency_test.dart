import "package:cake_wallet/entities/fiat_currency.dart";
import "package:cake_wallet/routes.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";

import "../../core/app_launcher.dart";
import "../../flows/onboarding_flows.dart";
import "../../robots/display_settings_page_robot.dart";
import "../../robots/home_page_robot.dart";
import "../../robots/new_dashboard_robot.dart";
import "../../robots/new_settings_page_robot.dart";
import "../../robots/new_swap_page_robot.dart";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  integrationTest("Swap uses the selected fiat for cached assets after USD/UAH changes",
      (tester) async {
    final app = AppLauncher(tester);
    final onboarding = OnboardingFlows(tester);
    final dashboard = NewDashboardRobot(tester);
    final home = HomePageRobot(tester);
    final settings = NewSettingsPageRobot(tester);
    final display = DisplaySettingsPageRobot(tester);
    final swap = NewSwapPageRobot(tester);

    await app.launchApp(testKey: "swap_fiat_currency_test_app_key");
    await onboarding.createFirstWallet(WalletType.solana);
    await dashboard.isDisplayed();
    await home.isDisplayed();

    await home.openSettingsSheet();
    await settings.openRow(Routes.displaySettingsPage);
    await display.openFiatCurrencyPicker();
    await display.chooseFiatCurrency(FiatCurrency.usd);
    await display.goBack();
    await settings.dismissModal();

    await home.openSwapSheet();
    await swap.isDisplayed();
    await swap.chooseReceiveCurrency(CryptoCurrency.xmr);
    await swap.enterDepositAmount("1");
    await swap.confirmQuoteReceived();
    await swap.confirmFiatConversion(FiatCurrency.usd);
    await swap.dismissModal();

    await home.openSettingsSheet();
    await settings.openRow(Routes.displaySettingsPage);
    await display.openFiatCurrencyPicker();
    await display.chooseFiatCurrency(FiatCurrency.uah);
    await display.goBack();
    await settings.dismissModal();

    await home.openSwapSheet();
    await swap.isDisplayed();
    await swap.chooseReceiveCurrency(CryptoCurrency.xmr);
    await swap.enterDepositAmount("1");
    await swap.confirmQuoteReceived();
    await swap.confirmFiatConversion(FiatCurrency.uah);
    await swap.confirmFiatConversion(FiatCurrency.uah, receiver: false);
    final cryptoAmount = swap.depositCryptoAmount;
    await swap.useDepositFiatInput();
    expect(swap.depositCryptoAmount, cryptoAmount);
    await swap.changeFiatCurrency(FiatCurrency.usd);
    expect(
      swap.depositCryptoAmount,
      cryptoAmount,
      reason: "Changing fiat must preserve the crypto amount even in fiat input mode",
    );
    await swap.useDepositFiatInput(enabled: false);
    await swap.confirmFiatConversion(FiatCurrency.usd);
    await swap.confirmFiatConversion(FiatCurrency.usd, receiver: false);
    await swap.dismissModal();
  });
}
