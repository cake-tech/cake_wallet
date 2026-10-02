import "package:cake_wallet/di.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/viewmodels/wallet_network/network_details_bloc.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";

import "../../core/app_launcher.dart";
import "../../core/test_wallets.dart";
import "../../flows/evm_network_flows.dart";
import "../../flows/wallet_flows.dart";
import "../../robots/add_evm_networks_disclaimer_page_robot.dart";
import "../../robots/home_page_robot.dart";
import "../../robots/manage_evm_networks_page_robot.dart";
import "../../robots/network_details_page_robot.dart";
import "../../robots/new_receive_page_robot.dart";
import "../../robots/wallet_network_page_robot.dart";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  integrationTest("A Popular EVM network can be found, enabled and used for a wallet",
      (tester) async {
    final appLauncher = AppLauncher(tester);
    final evmNetworkFlows = EvmNetworkFlows(tester);
    final walletFlows = WalletFlows(tester);
    final pickerRobot = WalletNetworkPageRobot(tester);
    final disclaimerRobot = AddEvmNetworksDisclaimerPageRobot(tester);
    final manageRobot = ManageEvmNetworksPageRobot(tester);
    final detailsRobot = NetworkDetailsPageRobot(tester);
    final homePageRobot = HomePageRobot(tester);
    final receiveRobot = NewReceivePageRobot(tester);

    const opChainId = 10;
    const opName = "OP Mainnet";
    const avalancheChainId = 43114;
    const walletName = "OP Test Wallet";

    await appLauncher.launchApp(testKey: "evm_popular_network_test_app_key");

    await evmNetworkFlows.openCreatePickerAtOnboarding();

    expect(pickerRobot.hasAddedNetworkRow(opChainId), false);

    await evmNetworkFlows.openManageEvmNetworksThroughDisclaimer();

    // Search by chain ID, by name, a network only ChainList's A-Z has, and a miss
    await manageRobot.search("$opChainId");
    await manageRobot.waitForRow(opChainId);

    await manageRobot.search("OP Main");
    await manageRobot.waitForRow(opChainId);

    await manageRobot.search("Avalanche");
    await manageRobot.waitForRow(avalancheChainId, timeout: const Duration(seconds: 90));

    await manageRobot.search("zzqq");

    expect(await manageRobot.waitForNoMatch(), true, reason: "A search with no match said nothing");
    expect(manageRobot.hasRow(opChainId), false);

    await manageRobot.clearSearch();

    expect(manageRobot.isEnabled(opChainId), false, reason: "OP started enabled");

    await evmNetworkFlows.enableNetwork(opChainId, searchQuery: opName);

    await manageRobot.goBackToPicker();
    await pickerRobot.isDisplayed();

    expect(
      await pickerRobot.waitForAddedNetworkRow(opChainId, present: true),
      true,
      reason: "Enabled OP is not offered in the picker",
    );
    expect(pickerRobot.hasManageAddedNetworksRow, true);
    expect(pickerRobot.hasAddEvmNetworksRow, false);

    // With a network added the disclaimer is skipped
    await pickerRobot.openManageAddedNetworks();
    await manageRobot.isDisplayed();

    expect(disclaimerRobot.isShowing, false, reason: "Manage Added Networks showed the disclaimer");

    await manageRobot.goBackToPicker();
    await pickerRobot.isDisplayed();

    await evmNetworkFlows.createWalletOnAddedNetwork(opChainId, walletName: walletName);

    await homePageRobot.isDisplayed();

    final appStore = getIt.get<AppStore>();
    final wallet = appStore.wallet!;

    expect(wallet.name, walletName);
    expect(wallet.type, WalletType.evm);
    expect(wallet.walletInfo.chainId, opChainId);
    expect(wallet.currency.title, "ETH");

    await homePageRobot.hasWalletName(walletName);
    await evmNetworkFlows.confirmDashboardShowsNetwork(opName, "ETH");

    final address = wallet.walletAddresses.address;

    expect(
      RegExp(r"^0x[0-9a-fA-F]{40}$").hasMatch(address),
      true,
      reason: "The OP wallet address $address is not an EVM address",
    );

    await homePageRobot.openReceiveSheet();
    await receiveRobot.isDisplayed();
    await receiveRobot.confirmAddressMatches(address);
    await receiveRobot.dismissModal();
    await homePageRobot.isDisplayed();

    // Finding the row in the wallet list and opening it proves the list shows it
    await walletFlows.switchToWallet(walletName);

    // A network with a wallet cannot be disabled and its core fields are locked
    await evmNetworkFlows.openCreatePickerFromWalletList();

    expect(pickerRobot.hasAddedNetworkRow(opChainId), true);

    await pickerRobot.openManageAddedNetworks();
    await manageRobot.isDisplayed();

    await manageRobot.search(opName);
    await manageRobot.waitForRow(opChainId);
    await manageRobot.tapToggle(opChainId);

    final refusal = await manageRobot.waitForRefusal();

    expect(refusal, S.current.network_used_cannot_disable(opName, "1"));

    await manageRobot.dismissRefusal();

    expect(
      await manageRobot.pumpUntil(() => manageRobot.isEnabled(opChainId) == true),
      true,
      reason: "OP was turned off despite having a wallet",
    );

    await manageRobot.clearSearch();

    await evmNetworkFlows.openNetworkDetails(opChainId, searchQuery: opName);

    for (final field in [NetworkField.rpcUrl, NetworkField.chainId, NetworkField.symbol]) {
      expect(
        detailsRobot.isReadOnly(field),
        true,
        reason: "${field.name} is editable on a network that has a wallet",
      );
    }

    expect(detailsRobot.isReadOnly(NetworkField.name), false);
    expect(detailsRobot.hasNodesManagedNote, true);
    expect(detailsRobot.isDeleteShown, false, reason: "A Popular network offered Delete");
    expect(detailsRobot.getFieldValue(NetworkField.rpcUrl), startsWith("https://"));

    // Reset to Default puts the ChainList name back without saving
    await detailsRobot.enterField(NetworkField.name, "OP Renamed");
    await detailsRobot.tapResetToDefault();

    expect(
      await detailsRobot.pumpUntil(() => detailsRobot.getFieldValue(NetworkField.name) == opName),
      true,
      reason: "Reset to Default left the name as ${detailsRobot.getFieldValue(NetworkField.name)}",
    );

    await detailsRobot.closeForm();
    await manageRobot.isDisplayed();

    // Saving a rename on a Popular network closes the form and renames the row
    await evmNetworkFlows.openNetworkDetails(opChainId, searchQuery: opName);

    await detailsRobot.enterField(NetworkField.name, "OP Renamed");
    await detailsRobot.saveExpectingClose();
    await manageRobot.isDisplayed();

    await manageRobot.search("OP Renamed");
    await manageRobot.waitForRow(opChainId);

    await evmNetworkFlows.openNetworkDetails(opChainId, searchQuery: "OP Renamed");

    await detailsRobot.enterField(NetworkField.name, opName);
    await detailsRobot.saveExpectingClose();
    await manageRobot.isDisplayed();

    await manageRobot.clearSearch();

    await manageRobot.goBackToPicker();
    await pickerRobot.closePicker();

    // The restore picker lists added networks too
    await evmNetworkFlows.openRestorePickerFromWalletList();

    expect(
      await pickerRobot.waitForAddedNetworkRow(opChainId, present: true),
      true,
      reason: "The restore picker does not offer the added OP network",
    );
    expect(pickerRobot.hasManageAddedNetworksRow, true);

    await evmNetworkFlows.restoreWalletOnAddedNetwork(
      opChainId,
      seed: TestWallets.seedFor(WalletType.ethereum),
    );

    final restored = getIt.get<AppStore>().wallet!;
    expect(restored.type, WalletType.evm);
    expect(restored.walletInfo.chainId, opChainId);
    expect(
      restored.walletAddresses.address.toLowerCase(),
      TestWallets.receiveAddressFor(WalletType.ethereum).toLowerCase(),
      reason: "The Ethereum test seed should restore the same address on OP",
    );
  });
}
