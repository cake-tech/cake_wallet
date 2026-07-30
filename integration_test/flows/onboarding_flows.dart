import "dart:io";

import "package:cake_wallet/entities/seed_type.dart";
import "package:cake_wallet/reactions/wallet_utils.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";

import "../core/test_config.dart";
import "../core/test_wallets.dart";
import "../robots/create_pin_welcome_page_robot.dart";
import "../robots/lightning_username_page_robot.dart";
import "../robots/new_wallet_page_robot.dart";
import "../robots/new_wallet_type_page_robot.dart";
import "../robots/pre_seed_page_robot.dart";
import "../robots/restore_from_seed_or_key_robot.dart";
import "../robots/restore_options_page_robot.dart";
import "../robots/seed_verification_page_robot.dart";
import "../robots/setup_pin_code_robot.dart";
import "../robots/wallet_group_description_page_robot.dart";
import "../robots/wallet_list_page_robot.dart";
import "../robots/wallet_seed_page_robot.dart";
import "../robots/welcome_page_robot.dart";

/// Multi-screen journeys covering first install onboarding and wallet creation.
class OnboardingFlows {
  OnboardingFlows(this.tester)
      : _welcomePageRobot = WelcomePageRobot(tester),
        _preSeedPageRobot = PreSeedPageRobot(tester),
        _setupPinCodeRobot = SetupPinCodeRobot(tester),
        _newWalletPageRobot = NewWalletPageRobot(tester),
        _walletSeedPageRobot = WalletSeedPageRobot(tester),
        _walletListPageRobot = WalletListPageRobot(tester),
        _newWalletTypePageRobot = NewWalletTypePageRobot(tester),
        _seedVerificationPageRobot = SeedVerificationPageRobot(tester),
        _createPinWelcomePageRobot = CreatePinWelcomePageRobot(tester),
        _restoreOptionsPageRobot = RestoreOptionsPageRobot(tester),
        _restoreFromSeedOrKeysPageRobot = RestoreFromSeedOrKeysPageRobot(tester),
        _lightningUsernamePageRobot = LightningUsernamePageRobot(tester),
        _walletGroupDescriptionPageRobot = WalletGroupDescriptionPageRobot(tester);

  final WidgetTester tester;

  final WelcomePageRobot _welcomePageRobot;
  final PreSeedPageRobot _preSeedPageRobot;
  final SetupPinCodeRobot _setupPinCodeRobot;
  final NewWalletPageRobot _newWalletPageRobot;
  final WalletSeedPageRobot _walletSeedPageRobot;
  final WalletListPageRobot _walletListPageRobot;
  final NewWalletTypePageRobot _newWalletTypePageRobot;
  final SeedVerificationPageRobot _seedVerificationPageRobot;
  final CreatePinWelcomePageRobot _createPinWelcomePageRobot;
  final RestoreOptionsPageRobot _restoreOptionsPageRobot;
  final RestoreFromSeedOrKeysPageRobot _restoreFromSeedOrKeysPageRobot;
  final LightningUsernamePageRobot _lightningUsernamePageRobot;
  final WalletGroupDescriptionPageRobot _walletGroupDescriptionPageRobot;

  /// Runs the fresh install path, from the pin welcome screen to an opened wallet.
  Future<void> createFirstWallet(WalletType type, {List<int>? pin}) async {
    await _createPinWelcomePageRobot.tapSetAPinButton();

    await setupPinCode(pin ?? TestConfig.pin);

    await _welcomePageRobot.navigateToCreateNewWalletPage();

    await _selectWalletType(type);

    // BIP39 chains land on the wallet group description page before naming the wallet.
    if (_welcomePageRobot.hasNewSingleSeedButton()) {
      await _welcomePageRobot.tapNewSingleSeed();
    }

    await _completeWalletCreationSteps(type);
  }

  /// Creates one more wallet starting from the wallet list tab.
  Future<void> createAdditionalWalletFromWalletList(WalletType type) async {
    tester.printToConsole("Creating ${type.name} wallet");

    await _walletListPageRobot.navigateToCreateNewWalletPage();

    await _selectWalletType(type);

    if (isBIP39Wallet(type)) {
      await _walletGroupDescriptionPageRobot.isWalletGroupDescriptionPage();
      await _walletGroupDescriptionPageRobot.navigateToCreateNewSeedPage();
    }

    await _completeWalletCreationSteps(type);
  }

  /// Runs the fresh install path restoring the first wallet from its seed phrase.
  Future<void> restoreFirstWalletFromSeed(WalletType type, {String? seed, List<int>? pin}) async {
    await _createPinWelcomePageRobot.tapSetAPinButton();

    await setupPinCode(pin ?? TestConfig.pin);

    await _welcomePageRobot.navigateToRestoreWalletPage();

    // Desktop skips the restore options page and goes straight to the type list.
    if (!Platform.isLinux) {
      await _restoreOptionsPageRobot.navigateToRestoreFromSeedsOrKeysPage();
    }

    await _selectWalletType(type);

    await _restoreFromSeed(type, seed ?? TestWallets.seedFor(type));
  }

  /// Restores one more wallet starting from the wallet list tab.
  Future<void> restoreAdditionalWalletFromWalletList(WalletType type, {String? seed}) async {
    tester.printToConsole("Restoring ${type.name} wallet");

    await _walletListPageRobot.navigateToRestoreWalletOptionsPage();

    if (!Platform.isLinux) {
      await _restoreOptionsPageRobot.navigateToRestoreFromSeedsOrKeysPage();
    }

    await _selectWalletType(type);

    await _restoreFromSeed(type, seed ?? TestWallets.seedFor(type));
  }

  Future<void> _restoreFromSeed(WalletType type, String seed) async {
    await _restoreFromSeedOrKeysPageRobot.selectWalletNameFromAvailableOptions();
    await _restoreFromSeedOrKeysPageRobot.enterSeedPhraseForWalletRestore(seed);

    // 25 word monero seeds are legacy seeds and need their restore block height entered.
    if (seed.split(" ").length == 25 && type == WalletType.monero) {
      await _restoreFromSeedOrKeysPageRobot
          .chooseSeedTypeForMoneroOrWowneroWallets(MoneroSeedType.legacy);
      await _restoreFromSeedOrKeysPageRobot
          .enterBlockHeightForWalletRestore(TestWallets.moneroRestoreBlockHeight);
    }

    if (Platform.isLinux) {
      final password = TestConfig.pin.join("");
      await _restoreFromSeedOrKeysPageRobot.enterPasswordForWalletRestore(password);
      await _restoreFromSeedOrKeysPageRobot.enterPasswordRepeatForWalletRestore(password);
    }

    await _restoreFromSeedOrKeysPageRobot.onRestoreWalletButtonPressed();
  }

  Future<void> setupPinCode(List<int> pin) async {
    // Desktop builds take a wallet password on the new wallet form instead of a pin.
    if (Platform.isLinux) {
      return;
    }

    await _setupPinCodeRobot.isSetupPinCodePage();

    await _setupPinCodeRobot.enterPinCode(pin);
    await _setupPinCodeRobot.enterPinCode(pin);
    await _setupPinCodeRobot.tapSuccessButton();
  }

  Future<void> _selectWalletType(WalletType type) async {
    await _newWalletTypePageRobot.isNewWalletTypePage();

    await _newWalletTypePageRobot.findParticularWalletTypeInScrollableList(type);
    await _newWalletTypePageRobot.selectWalletType(type);
  }

  Future<void> _completeWalletCreationSteps(WalletType type) async {
    await _generateNewWalletDetails();

    await _preSeedPageRobot.isPreSeedPage();
    await _preSeedPageRobot.onConfirmButtonPressed();

    await _confirmWalletSeedDetails();

    await _verifyWalletSeed();

    // Bitcoin wallets set up a lightning username after seed verification, skip it.
    if (type == WalletType.bitcoin) {
      await _lightningUsernamePageRobot.isDisplayed();
      await _lightningUsernamePageRobot.tapSkip();
    }
  }

  Future<void> _generateNewWalletDetails() async {
    await _newWalletPageRobot.isNewWalletPage();

    await _newWalletPageRobot.generateWalletName();

    if (Platform.isLinux) {
      final password = TestConfig.pin.join("");
      await _restoreFromSeedOrKeysPageRobot.enterPasswordForWalletRestore(password);
      await _restoreFromSeedOrKeysPageRobot.enterPasswordRepeatForWalletRestore(password);
    }

    await _newWalletPageRobot.onNextButtonPressed();
  }

  Future<void> _confirmWalletSeedDetails() async {
    await _walletSeedPageRobot.isWalletSeedPage();

    _walletSeedPageRobot.confirmWalletDetailsDisplayCorrectly();
    _walletSeedPageRobot.confirmWalletSeedReminderDisplays();

    await _walletSeedPageRobot.onVerifySeedButtonPressed();
  }

  Future<void> _verifyWalletSeed() async {
    await _seedVerificationPageRobot.isSeedVerificationPage();

    _seedVerificationPageRobot.hasTitle();

    await _seedVerificationPageRobot.verifyWalletSeeds();
  }
}
