import 'package:cw_core/wallet_type.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cake_wallet/main.dart' as app;

import '../robots/dashboard_page_robot.dart';
import '../robots/disclaimer_page_robot.dart';
import '../robots/new_wallet_type_page_robot.dart';
import '../robots/restore_from_seed_or_key_robot.dart';
import '../robots/restore_options_page_robot.dart';
import '../robots/setup_pin_code_robot.dart';
import '../robots/wallet_list_page_robot.dart';
import '../robots/welcome_page_robot.dart';
import 'common_test_cases.dart';
import 'common_test_constants.dart';
import 'package:cake_wallet/.secrets.g.dart' as secrets;

class CommonTestFlows {
  CommonTestFlows(this._tester)
      : _commonTestCases = CommonTestCases(_tester),
        _welcomePageRobot = WelcomePageRobot(_tester),
        _setupPinCodeRobot = SetupPinCodeRobot(_tester),
        _dashboardPageRobot = DashboardPageRobot(_tester),
        _walletListPageRobot = WalletListPageRobot(_tester),
        _disclaimerPageRobot = DisclaimerPageRobot(_tester),
        _newWalletTypePageRobot = NewWalletTypePageRobot(_tester),
        _restoreOptionsPageRobot = RestoreOptionsPageRobot(_tester),
        _restoreFromSeedOrKeysPageRobot = RestoreFromSeedOrKeysPageRobot(_tester);

  final WidgetTester _tester;
  final CommonTestCases _commonTestCases;

  final WelcomePageRobot _welcomePageRobot;
  final SetupPinCodeRobot _setupPinCodeRobot;
  final DashboardPageRobot _dashboardPageRobot;
  final DisclaimerPageRobot _disclaimerPageRobot;
  final WalletListPageRobot _walletListPageRobot;
  final NewWalletTypePageRobot _newWalletTypePageRobot;
  final RestoreOptionsPageRobot _restoreOptionsPageRobot;
  final RestoreFromSeedOrKeysPageRobot _restoreFromSeedOrKeysPageRobot;

  String getWalletSeedsByWalletType(WalletType walletType) {
    switch (walletType) {
      case WalletType.monero:
        return secrets.moneroTestWalletSeeds;
      case WalletType.bitcoin:
        return secrets.bitcoinTestWalletSeeds;
      case WalletType.ethereum:
        return secrets.ethereumTestWalletSeeds;
      case WalletType.litecoin:
        return secrets.litecoinTestWalletSeeds;
      case WalletType.bitcoinCash:
        return secrets.bitcoinCashTestWalletSeeds;
      case WalletType.polygon:
        return secrets.polygonTestWalletSeeds;
      case WalletType.solana:
        return secrets.solanaTestWalletSeeds;
      case WalletType.tron:
        return secrets.tronTestWalletSeeds;
      case WalletType.nano:
        return secrets.nanoTestWalletSeeds;
      case WalletType.wownero:
        return secrets.wowneroTestWalletSeeds;
      default:
        return '';
    }
  }

  String getReceiveAddressByWalletType(WalletType walletType) {
    switch (walletType) {
      case WalletType.monero:
        return secrets.moneroTestWalletReceiveAddress;
      case WalletType.bitcoin:
        return secrets.bitcoinTestWalletReceiveAddress;
      case WalletType.ethereum:
        return secrets.ethereumTestWalletReceiveAddress;
      case WalletType.litecoin:
        return secrets.litecoinTestWalletReceiveAddress;
      case WalletType.bitcoinCash:
        return secrets.bitcoinCashTestWalletReceiveAddress;
      case WalletType.polygon:
        return secrets.polygonTestWalletReceiveAddress;
      case WalletType.solana:
        return secrets.solanaTestWalletReceiveAddress;
      case WalletType.tron:
        return secrets.tronTestWalletReceiveAddress;
      case WalletType.nano:
        return secrets.nanoTestWalletReceiveAddress;
      case WalletType.wownero:
        return secrets.wowneroTestWalletReceiveAddress;
      default:
        return '';
    }
  }

  Future<void> startAppFlow(Key key) async {
    await app.main(topLevelKey: ValueKey('send_flow_test_app_key'));

    await _tester.pumpAndSettle();

    // --------- Disclaimer Page ------------
    // Tap checkbox to accept disclaimer
    await _disclaimerPageRobot.tapDisclaimerCheckbox();

    // Tap accept button
    await _disclaimerPageRobot.tapAcceptButton();
  }

  Future<void> welcomePageToRestoreWalletThroughSeedsFlow(
    WalletType walletTypeToRestore,
    String walletSeed,
  ) async {
    await _welcomeToRestoreFromSeedsOrKeysPath(walletTypeToRestore);
    await _restoreFromSeeds(walletSeed);
  }

  Future<void> welcomePageToRestoreWalletThroughKeysFlow(
    WalletType walletTypeToRestore,
  ) async {
    await _welcomeToRestoreFromSeedsOrKeysPath(walletTypeToRestore);
    await _restoreFromKeys();
  }

  Future<void> switchToWalletMenuFromDashboardPage() async {
    _tester.printToConsole('Switching to Wallet Menu');
    await _dashboardPageRobot.openDrawerMenu();
    await _commonTestCases.defaultSleepTime();

    await _dashboardPageRobot.dashboardMenuWidgetRobot.navigateToWalletMenu();
    await _commonTestCases.defaultSleepTime();
  }

  Future<void> restoreWalletFromWalletMenu(
    WalletType walletType,
    String walletSeed,
  ) async {
    _tester.printToConsole('Restoring ${walletType.name} Wallet');
    await _walletListPageRobot.navigateToRestoreWalletOptionsPage();
    await _commonTestCases.defaultSleepTime();

    await _restoreOptionsPageRobot.navigateToRestoreFromSeedsOrKeysPage();
    await _commonTestCases.defaultSleepTime();

    await _selectWalletTypeForWallet(walletType);
    await _commonTestCases.defaultSleepTime();

    await _restoreFromSeeds(walletSeed);
    await _commonTestCases.defaultSleepTime();
  }

  Future<void> _welcomeToRestoreFromSeedsOrKeysPath(WalletType walletTypeToRestore) async {
    // --------- Welcome Page ---------------
    await _welcomePageRobot.navigateToRestoreWalletPage();

    // ----------- Restore Options Page -----------
    // Route to restore from seeds or keys page to continue flow
    await _restoreOptionsPageRobot.navigateToRestoreFromSeedsOrKeysPage();

    // ----------- SetupPinCode Page -------------
    // Confirm initial defaults - Widgets to be displayed etc
    await _setupPinCodeRobot.isSetupPinCodePage();

    await _setupPinCodeRobot.enterPinCode(CommonTestConstants.pin, true);
    await _setupPinCodeRobot.enterPinCode(CommonTestConstants.pin, false);
    await _setupPinCodeRobot.tapSuccessButton();

    await _selectWalletTypeForWallet(walletTypeToRestore);
  }

  Future<void> _selectWalletTypeForWallet(WalletType type) async {
    // ----------- NewWalletType Page -------------
    // Confirm scroll behaviour works properly
    await _newWalletTypePageRobot.findParticularWalletTypeInScrollableList(type);

    // Select a wallet and route to next page
    await _newWalletTypePageRobot.selectWalletType(type);
    await _newWalletTypePageRobot.onNextButtonPressed();
  }

  // Main Restore Actions - On the RestoreFromSeed/Keys Page
  Future<void> _restoreFromSeeds(String walletSeed) async {
    // ----------- RestoreFromSeedOrKeys Page -------------

    await _restoreFromSeedOrKeysPageRobot.selectWalletNameFromAvailableOptions();
    await _restoreFromSeedOrKeysPageRobot.enterSeedPhraseForWalletRestore(walletSeed);
    await _restoreFromSeedOrKeysPageRobot.onRestoreWalletButtonPressed();
  }

  Future<void> _restoreFromKeys() async {
    await _commonTestCases.swipePage();
    await _commonTestCases.defaultSleepTime();

    await _restoreFromSeedOrKeysPageRobot.selectWalletNameFromAvailableOptions(
      isSeedFormEntry: false,
    );

    await _restoreFromSeedOrKeysPageRobot.enterSeedPhraseForWalletRestore('');
    await _restoreFromSeedOrKeysPageRobot.onRestoreWalletButtonPressed();
  }
}
