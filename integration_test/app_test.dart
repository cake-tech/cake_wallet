
import 'package:cake_wallet/main.dart' as app;
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'robots/dashboard_page_robot.dart';
import 'robots/disclaimer_page_robot.dart';
import 'robots/new_wallet_type_page_robot.dart';
import 'robots/restore_from_seed_or_key_robot.dart';
import 'robots/restore_options_page_robot.dart';
import 'robots/setup_pin_code_robot.dart';
import 'robots/welcome_page_robot.dart';

Future<void> restoreFlutterError() async {
  final originalOnError = FlutterError.onError!;

  // restore FlutterError.onError
  FlutterError.onError = (FlutterErrorDetails details) {
    originalOnError(details);
  };
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  DisclaimerPageRobot disclaimerPageRobot;
  WelcomePageRobot welcomePageRobot;
  SetupPinCodeRobot setupPinCodeRobot;
  RestoreOptionsPageRobot restoreOptionsPageRobot;
  NewWalletTypePageRobot newWalletTypePageRobot;
  RestoreFromSeedOrKeysPageRobot restoreFromSeedOrKeysPageRobot;
  DashboardPageRobot dashboardPageRobot;

  group('Startup Test', () {
    testWidgets('Test for Exchange flow using Restore Wallet - Exchanging USDT(Sol) to SOL',
        (tester) async {
      disclaimerPageRobot = DisclaimerPageRobot(tester);
      welcomePageRobot = WelcomePageRobot(tester);
      setupPinCodeRobot = SetupPinCodeRobot(tester);
      restoreOptionsPageRobot = RestoreOptionsPageRobot(tester);
      newWalletTypePageRobot = NewWalletTypePageRobot(tester);
      restoreFromSeedOrKeysPageRobot = RestoreFromSeedOrKeysPageRobot(tester);
      dashboardPageRobot = DashboardPageRobot(tester);

      await app.main();
      await tester.pumpAndSettle();

      // --------- Disclaimer Page ------------
      // Confirm initial defaults
      // await disclaimerPageRobot.isDisclaimerPage();
      // disclaimerPageRobot.hasCheckIcon(false);
      // disclaimerPageRobot.hasDisclaimerCheckbox();

      // Tap checkbox to accept disclaimer
      await disclaimerPageRobot.tapDisclaimerCheckbox();

      // Confirm that page has been updated with the check mark icon in checkbox
      // disclaimerPageRobot.hasCheckIcon(true);

      // Tap accept button
      await disclaimerPageRobot.tapAcceptButton();
      tester.printToConsole('Routing to Welcome Page');

      // --------- Welcome Page ---------------
      // Confirm initial defaults
      // await welcomePageRobot.isWelcomePage();
      // welcomePageRobot.confirmActionButtonsDisplay();

      // Confirm routing to Create Wallet Page works
      // await welcomePageRobot.navigateToCreateNewWalletPage();
      // await welcomePageRobot.backAndVerify();

      // Confirm routing to Restore Wallet Page works
      // await welcomePageRobot.navigateToRestoreWalletPage();
      // await welcomePageRobot.backAndVerify();

      // Route to restore wallet to continue flow
      await welcomePageRobot.navigateToRestoreWalletPage();
      tester.printToConsole('Routing to Restore Wallet Page');

      // ----------- Restore Options Page -----------
      // Confirm initial defaults
      // await restoreOptionsPageRobot.isRestoreOptionsPage();
      // restoreOptionsPageRobot.hasRestoreOptionsButton();

      // Confirm routing to Restore from seeds Page works
      // await restoreOptionsPageRobot.navigateToRestoreFromSeedsPage();
      // await restoreOptionsPageRobot.backAndVerify();

      // Confirm routing to Restore from backup Page works
      // await restoreOptionsPageRobot.navigateToRestoreFromBackupPage();
      // await restoreOptionsPageRobot.backAndVerify();

      // Confirm routing to Restore from hardware wallet Page works
      // await restoreOptionsPageRobot.navigateToRestoreFromHardwareWalletPage();
      // await restoreOptionsPageRobot.backAndVerify();

      // Route to restore from seeds page to continue flow
      await restoreOptionsPageRobot.navigateToRestoreFromSeedsPage();

      // ----------- SetupPinCode Page -------------
      // Confirm initial defaults - Widgets to be displayed etc
      // await setupPinCodeRobot.isSetupPinCodePage();
      // setupPinCodeRobot.hasPinCodeWidget();
      // setupPinCodeRobot.hasTitle();
      // setupPinCodeRobot.hasNumberButtonsVisible();

      await setupPinCodeRobot.enterPinCode(true);
      await setupPinCodeRobot.enterPinCode(false);
      await setupPinCodeRobot.tapSuccessButton();

      // ----------- NewWalletType Page -------------
      // Confirm initial defaults - Widgets to be displayed etc
      // await newWalletTypePageRobot.isNewWalletTypePage();
      // newWalletTypePageRobot.displaysCorrectTitle(false);
      // newWalletTypePageRobot.displaysCorrectImage(ThemeType.dark);
      // newWalletTypePageRobot.hasWalletTypeForm();

      // Confirm scroll behaviour works properly
      await newWalletTypePageRobot.findParticularWalletTypeInScrollableList(WalletType.haven);

      // Select a wallet and route to next page
      await newWalletTypePageRobot.selectWalletType(WalletType.solana);
      await newWalletTypePageRobot.onNextButtonTapped();

      // ----------- RestoreFromSeedOrKeys Page -------------
      // Confirm initial defaults - Widgets to be displayed etc
      // await restoreFromSeedOrKeysPageRobot.isRestoreFromSeedKeyPage();
      // await restoreFromSeedOrKeysPageRobot.confirmViewComponentsDisplayProperlyPerPageView();
      // restoreFromSeedOrKeysPageRobot.confirmRestoreButtonDisplays();
      // restoreFromSeedOrKeysPageRobot.confirmAdvancedSettingButtonDisplays();

      await restoreFromSeedOrKeysPageRobot.enterWalletNameText('Integrated Testing Wallet');
      await restoreFromSeedOrKeysPageRobot.enterSeedPhraseForWalletRestore(
        'noble define inflict tackle sweet essence mention bicycle word hard patient ketchup',
      );
      await restoreFromSeedOrKeysPageRobot.onRestoreWalletButtonTapped();

      // ----------- RestoreFromSeedOrKeys Page -------------
      await dashboardPageRobot.isDashboardPage();
      dashboardPageRobot.confirmServiceUpdateButtonDisplays();
      dashboardPageRobot.confirmMenuButtonDisplays();
      dashboardPageRobot.confirmSyncIndicatorButtonDisplays();
      await dashboardPageRobot.confirmRightCryptoAssetTitleDisplaysPerPageView(WalletType.solana);

      await dashboardPageRobot.navigateToExchangePage();
      await Future.delayed(Duration(seconds: 5));
    });
  });
}
