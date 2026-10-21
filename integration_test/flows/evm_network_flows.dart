import "dart:io";

import "package:cake_wallet/new-ui/pages/home_page.dart";
import "package:cake_wallet/src/screens/new_wallet/new_wallet_page.dart";
import "package:cake_wallet/src/screens/new_wallet/wallet_group_description_page.dart";
import "package:flutter_test/flutter_test.dart";

import "../core/test_config.dart";
import "../robots/add_evm_networks_disclaimer_page_robot.dart";
import "../robots/create_pin_welcome_page_robot.dart";
import "../robots/home_page_robot.dart";
import "../robots/manage_evm_networks_page_robot.dart";
import "../robots/network_details_page_robot.dart";
import "../robots/new_dashboard_robot.dart";
import "../robots/new_wallet_page_robot.dart";
import "../robots/pre_seed_page_robot.dart";
import "../robots/restore_from_seed_or_key_robot.dart";
import "../robots/restore_options_page_robot.dart";
import "../robots/seed_verification_page_robot.dart";
import "../robots/wallet_group_description_page_robot.dart";
import "../robots/wallet_list_page_robot.dart";
import "../robots/wallet_network_page_robot.dart";
import "../robots/wallet_seed_page_robot.dart";
import "../robots/welcome_page_robot.dart";
import "onboarding_flows.dart";

class EvmNetworkFlows {
  EvmNetworkFlows(this.tester)
      : _onboardingFlows = OnboardingFlows(tester),
        _createPinWelcomePageRobot = CreatePinWelcomePageRobot(tester),
        _welcomePageRobot = WelcomePageRobot(tester),
        _dashboardRobot = NewDashboardRobot(tester),
        _homePageRobot = HomePageRobot(tester),
        _restoreOptionsPageRobot = RestoreOptionsPageRobot(tester),
        _restoreFromSeedRobot = RestoreFromSeedOrKeysPageRobot(tester),
        _walletListPageRobot = WalletListPageRobot(tester),
        _pickerRobot = WalletNetworkPageRobot(tester),
        _disclaimerRobot = AddEvmNetworksDisclaimerPageRobot(tester),
        _manageRobot = ManageEvmNetworksPageRobot(tester),
        _detailsRobot = NetworkDetailsPageRobot(tester),
        _walletGroupDescriptionPageRobot = WalletGroupDescriptionPageRobot(tester),
        _newWalletPageRobot = NewWalletPageRobot(tester),
        _preSeedPageRobot = PreSeedPageRobot(tester),
        _walletSeedPageRobot = WalletSeedPageRobot(tester),
        _seedVerificationPageRobot = SeedVerificationPageRobot(tester);

  final WidgetTester tester;

  final OnboardingFlows _onboardingFlows;
  final CreatePinWelcomePageRobot _createPinWelcomePageRobot;
  final WelcomePageRobot _welcomePageRobot;
  final NewDashboardRobot _dashboardRobot;
  final HomePageRobot _homePageRobot;
  final RestoreOptionsPageRobot _restoreOptionsPageRobot;
  final RestoreFromSeedOrKeysPageRobot _restoreFromSeedRobot;
  final WalletListPageRobot _walletListPageRobot;
  final WalletNetworkPageRobot _pickerRobot;
  final AddEvmNetworksDisclaimerPageRobot _disclaimerRobot;
  final ManageEvmNetworksPageRobot _manageRobot;
  final NetworkDetailsPageRobot _detailsRobot;
  final WalletGroupDescriptionPageRobot _walletGroupDescriptionPageRobot;
  final NewWalletPageRobot _newWalletPageRobot;
  final PreSeedPageRobot _preSeedPageRobot;
  final WalletSeedPageRobot _walletSeedPageRobot;
  final SeedVerificationPageRobot _seedVerificationPageRobot;

  Future<void> openCreatePickerAtOnboarding() async {
    await _createPinWelcomePageRobot.tapSetAPinButton();

    await _onboardingFlows.setupPinCode(TestConfig.pin);

    await _welcomePageRobot.navigateToCreateNewWalletPage();

    await _pickerRobot.isDisplayed();
  }

  Future<void> openCreatePickerFromWalletList() async {
    await _dashboardRobot.openWalletsTab();
    await _walletListPageRobot.isDisplayed();

    await _walletListPageRobot.navigateToCreateNewWalletPage();

    await _pickerRobot.isDisplayed();
  }

  Future<void> openManageEvmNetworksThroughDisclaimer() async {
    await _pickerRobot.openAddEvmNetworks();

    await _disclaimerRobot.isDisplayed();
    await _disclaimerRobot.tapContinue();

    await _manageRobot.isDisplayed();
  }

  /// Leaves Manage EVM Networks with the search cleared
  Future<void> enableNetwork(int chainId, {required String searchQuery}) async {
    await _manageRobot.search(searchQuery);

    await _manageRobot.waitForRow(chainId);
    await _manageRobot.setEnabled(chainId, enabled: true);

    await _manageRobot.clearSearch();
  }

  Future<void> disableNetwork(int chainId, {required String searchQuery}) async {
    await _manageRobot.search(searchQuery);

    await _manageRobot.waitForRow(chainId);
    await _manageRobot.setEnabled(chainId, enabled: false);

    await _manageRobot.clearSearch();
  }

  Future<void> addNetworkManually({
    required String name,
    required String rpcUrl,
    required int chainId,
    required String symbol,
  }) async {
    await _manageRobot.openAddManually();
    await _detailsRobot.isDisplayed();

    await _detailsRobot.fillForm(
      name: name,
      rpcUrl: rpcUrl,
      chainId: chainId.toString(),
      symbol: symbol,
    );

    await _detailsRobot.saveExpectingClose();

    await _manageRobot.isDisplayed();
    await _manageRobot.waitForRow(chainId);
  }

  /// Starts on the picker, ends on the dashboard with the new wallet open
  Future<void> createWalletOnAddedNetwork(int chainId, {required String walletName}) async {
    await _pickerRobot.selectAddedNetwork(chainId);

    final nextStepShown = await _pickerRobot.pumpUntil(
      () =>
          tester.any(find.byType(WalletGroupDescriptionPage)) ||
          tester.any(find.byType(NewWalletPage)),
    );

    expect(nextStepShown, true, reason: "Selecting chain $chainId opened neither step");

    if (tester.any(find.byType(WalletGroupDescriptionPage))) {
      await _walletGroupDescriptionPageRobot.navigateToCreateNewSeedPage();
    }

    await _newWalletPageRobot.isDisplayed();
    await _newWalletPageRobot.enterWalletName(walletName);
    await _newWalletPageRobot.onNextButtonPressed();

    await _preSeedPageRobot.isDisplayed();
    await _preSeedPageRobot.onConfirmButtonPressed();

    await _walletSeedPageRobot.isDisplayed();
    _walletSeedPageRobot.confirmWalletDetailsDisplayCorrectly();
    await _walletSeedPageRobot.onVerifySeedButtonPressed();

    await _seedVerificationPageRobot.isDisplayed();
    await _seedVerificationPageRobot.verifyWalletSeeds();

    await _dashboardRobot.isDisplayed(timeout: const Duration(minutes: 1));
  }

  Future<void> openNetworkDetails(int chainId, {required String searchQuery}) async {
    await _manageRobot.search(searchQuery);
    await _manageRobot.waitForRow(chainId);

    await _manageRobot.openEdit(chainId);

    await _detailsRobot.isDisplayed();
  }

  Future<void> openRestorePickerFromWalletList() async {
    await _dashboardRobot.openWalletsTab();
    await _walletListPageRobot.isDisplayed();

    await _walletListPageRobot.navigateToRestoreWalletOptionsPage();

    if (!Platform.isLinux) {
      await _restoreOptionsPageRobot.navigateToRestoreFromSeedsOrKeysPage();
    }

    await _pickerRobot.isDisplayed();
  }

  Future<void> restoreWalletOnAddedNetwork(int chainId, {required String seed}) async {
    await _pickerRobot.selectAddedNetwork(chainId);

    await _restoreFromSeedRobot.isDisplayed();
    await _restoreFromSeedRobot.selectWalletNameFromAvailableOptions();
    await _restoreFromSeedRobot.enterSeedPhraseForWalletRestore(seed);

    if (Platform.isLinux) {
      final password = TestConfig.pin.join("");
      await _restoreFromSeedRobot.enterPasswordForWalletRestore(password);
      await _restoreFromSeedRobot.enterPasswordRepeatForWalletRestore(password);
    }

    await _restoreFromSeedRobot.onRestoreWalletButtonPressed();

    await _dashboardRobot.isDisplayed(timeout: const Duration(minutes: 1));
  }

  Future<void> confirmDashboardShowsNetwork(String networkName, String symbol) async {
    Finder onHome(String text) => find.descendant(
          of: find.byType(NewHomePage),
          matching: find.textContaining(text, findRichText: true),
        );

    final shown = await _homePageRobot.pumpUntil(
      () => tester.any(onHome(networkName)) && tester.any(onHome(symbol)),
    );

    expect(
      shown,
      true,
      reason: "The dashboard never showed both $networkName and $symbol "
          "(name: ${tester.any(onHome(networkName))}, symbol: ${tester.any(onHome(symbol))})",
    );
  }
}
