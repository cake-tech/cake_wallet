import 'package:cake_wallet/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'robots/disclaimer_page_robot.dart';
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

  group('Startup Test', () {
    testWidgets('Unauthenticated Startup flow', (tester) async {
      disclaimerPageRobot = DisclaimerPageRobot(tester);
      welcomePageRobot = WelcomePageRobot(tester);
      setupPinCodeRobot = SetupPinCodeRobot(tester);

      await app.main();
      await tester.pumpAndSettle();

      // --------- Disclaimer Page ------------
      // Confirm initial defaults
      await disclaimerPageRobot.isDisclaimerPage();
      disclaimerPageRobot.hasCheckIcon(false);
      disclaimerPageRobot.hasDisclaimerCheckbox();

      // Tap checkbox to accept disclaimer
      await disclaimerPageRobot.tapDisclaimerCheckbox();

      // Confirm that page has been updated with the check mark icon in checkbox
      disclaimerPageRobot.hasCheckIcon(true);

      // Tap accept button
      await disclaimerPageRobot.tapAcceptButton();
      tester.printToConsole('Routing to Welcome Page');

      // --------- Welcome Page ---------------
      // Confirm initial defaults - Widgets to be displayed etc
      await welcomePageRobot.isWelcomePage();
      welcomePageRobot.confirmActionButtonsDisplay();

      // Confirm routing to Create Wallet Page works
      await welcomePageRobot.navigateToCreateNewWalletPage();
      await welcomePageRobot.backAndVerify();

      // Confirm routing to Restore Wallet Page works
      await welcomePageRobot.navigateToRestoreWalletPage();
      await welcomePageRobot.backAndVerify();

      // Route to restore wallet to continue flow
      await welcomePageRobot.navigateToRestoreWalletPage();
      tester.printToConsole('Routing to Restore Wallet Page');

      // ----------- SetupPinCode Page -------------
      // Confirm initial defaults - Widgets to be displayed etc
      await setupPinCodeRobot.isSetupPinCodePage();
      setupPinCodeRobot.hasPinCodeWidget();
      setupPinCodeRobot.hasTitle();
      setupPinCodeRobot.hasNumberButtonsVisible();

      await setupPinCodeRobot.enterPinCode();
    });
  });
}
