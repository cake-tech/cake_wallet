import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cake_wallet/.secrets.g.dart' as secrets;
import 'package:cake_wallet/main.dart' as app;

import '../robots/disclaimer_page_robot.dart';
import '../robots/new_wallet_type_page_robot.dart';
import '../robots/restore_from_seed_or_key_robot.dart';
import '../robots/restore_options_page_robot.dart';
import '../robots/setup_pin_code_robot.dart';
import '../robots/welcome_page_robot.dart';
import 'common_test_cases.dart';
import 'common_test_constants.dart';

class CommonTestFlows {
  CommonTestFlows(this._tester)
      : _commonTestCases = CommonTestCases(_tester),
        _welcomePageRobot = WelcomePageRobot(_tester),
        _setupPinCodeRobot = SetupPinCodeRobot(_tester),
        _disclaimerPageRobot = DisclaimerPageRobot(_tester),
        _newWalletTypePageRobot = NewWalletTypePageRobot(_tester),
        _restoreOptionsPageRobot = RestoreOptionsPageRobot(_tester),
        _restoreFromSeedOrKeysPageRobot = RestoreFromSeedOrKeysPageRobot(_tester);

  final WidgetTester _tester;
  final CommonTestCases _commonTestCases;

  final WelcomePageRobot _welcomePageRobot;
  final SetupPinCodeRobot _setupPinCodeRobot;
  final DisclaimerPageRobot _disclaimerPageRobot;
  final NewWalletTypePageRobot _newWalletTypePageRobot;
  final RestoreOptionsPageRobot _restoreOptionsPageRobot;
  final RestoreFromSeedOrKeysPageRobot _restoreFromSeedOrKeysPageRobot;

  Future<void> startAppFlow(Key key) async {
    await app.main(topLevelKey: ValueKey('send_flow_test_app_key'));
    
    await _tester.pumpAndSettle();

    // --------- Disclaimer Page ------------
    // Tap checkbox to accept disclaimer
    await _disclaimerPageRobot.tapDisclaimerCheckbox();

    // Tap accept button
    await _disclaimerPageRobot.tapAcceptButton();
  }

  Future<void> restoreWalletThroughSeedsFlow() async {
    await _welcomeToRestoreFromSeedsPath();
    await _restoreFromSeeds();
  }

  Future<void> restoreWalletThroughKeysFlow() async {
    await _welcomeToRestoreFromSeedsPath();
    await _restoreFromKeys();
  }

  Future<void> _welcomeToRestoreFromSeedsPath() async {
    // --------- Welcome Page ---------------
    await _welcomePageRobot.navigateToRestoreWalletPage();

    // ----------- Restore Options Page -----------
    // Route to restore from seeds page to continue flow
    await _restoreOptionsPageRobot.navigateToRestoreFromSeedsPage();

    // ----------- SetupPinCode Page -------------
    // Confirm initial defaults - Widgets to be displayed etc
    await _setupPinCodeRobot.isSetupPinCodePage();

    await _setupPinCodeRobot.enterPinCode(CommonTestConstants.pin, true);
    await _setupPinCodeRobot.enterPinCode(CommonTestConstants.pin, false);
    await _setupPinCodeRobot.tapSuccessButton();

    // ----------- NewWalletType Page -------------
    // Confirm scroll behaviour works properly
    await _newWalletTypePageRobot
        .findParticularWalletTypeInScrollableList(CommonTestConstants.testWalletType);

    // Select a wallet and route to next page
    await _newWalletTypePageRobot.selectWalletType(CommonTestConstants.testWalletType);
    await _newWalletTypePageRobot.onNextButtonPressed();
  }

  Future<void> _restoreFromSeeds() async {
    // ----------- RestoreFromSeedOrKeys Page -------------
    await _restoreFromSeedOrKeysPageRobot.enterWalletNameText(CommonTestConstants.testWalletName);
    await _restoreFromSeedOrKeysPageRobot.enterSeedPhraseForWalletRestore(secrets.solanaTestWalletSeeds);
    await _restoreFromSeedOrKeysPageRobot.onRestoreWalletButtonPressed();
  }

  Future<void> _restoreFromKeys() async {
    await _commonTestCases.swipePage();
    await _commonTestCases.defaultSleepTime();

    await _restoreFromSeedOrKeysPageRobot.enterWalletNameText(CommonTestConstants.testWalletName);

    await _restoreFromSeedOrKeysPageRobot.enterSeedPhraseForWalletRestore('');
    await _restoreFromSeedOrKeysPageRobot.onRestoreWalletButtonPressed();
  }
}
