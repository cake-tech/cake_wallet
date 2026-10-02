import "package:cake_wallet/di.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/viewmodels/wallet_network/network_details_bloc.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";

import "../../core/app_launcher.dart";
import "../../flows/evm_network_flows.dart";
import "../../robots/add_evm_networks_disclaimer_page_robot.dart";
import "../../robots/home_page_robot.dart";
import "../../robots/manage_evm_networks_page_robot.dart";
import "../../robots/network_details_page_robot.dart";
import "../../robots/wallet_network_page_robot.dart";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  integrationTest("A manually added EVM network is validated, can be deleted, disabled and used",
      (tester) async {
    final appLauncher = AppLauncher(tester);
    final evmNetworkFlows = EvmNetworkFlows(tester);
    final pickerRobot = WalletNetworkPageRobot(tester);
    final disclaimerRobot = AddEvmNetworksDisclaimerPageRobot(tester);
    final manageRobot = ManageEvmNetworksPageRobot(tester);
    final detailsRobot = NetworkDetailsPageRobot(tester);
    final homePageRobot = HomePageRobot(tester);

    // Sepolia is a testnet, so ChainList's parsed feed never lists it and add mode accepts it
    const chainId = 11155111;
    const name = "Sepolia Test";
    const symbol = "SEP";
    const rpcUrl = "https://ethereum-sepolia-rpc.publicnode.com";
    const unlistedChainId = 987654;
    const walletName = "Manual Net Wallet";

    await appLauncher.launchApp(testKey: "evm_manual_network_test_app_key");

    await evmNetworkFlows.openCreatePickerAtOnboarding();
    await evmNetworkFlows.openManageEvmNetworksThroughDisclaimer();

    await manageRobot.openAddManually();
    await detailsRobot.isDisplayed();

    // Every required field is refused while empty
    await detailsRobot.saveExpectingError(NetworkField.name);

    for (final field in [
      NetworkField.name,
      NetworkField.rpcUrl,
      NetworkField.chainId,
      NetworkField.symbol,
    ]) {
      expect(detailsRobot.errorFor(field), S.current.field_required, reason: field.name);
    }

    // Values that break the format rules for name length, failover, chain ID and symbol
    await detailsRobot.fillForm(
      name: "N" * 33,
      rpcUrl: rpcUrl,
      chainId: "abc",
      symbol: "abcdefghijk",
    );
    await detailsRobot.revealFailover();
    await detailsRobot.enterField(NetworkField.failoverUrl, rpcUrl);

    expect(
      detailsRobot.getFieldValue(NetworkField.symbol),
      "ABCDEFGHIJK",
      reason: "The symbol is upper-cased while typing",
    );

    await detailsRobot.saveExpectingError(NetworkField.name);

    expect(detailsRobot.errorFor(NetworkField.name), S.current.network_name_too_long);
    expect(detailsRobot.errorFor(NetworkField.failoverUrl), S.current.failover_must_differ);
    expect(detailsRobot.errorFor(NetworkField.chainId), S.current.chain_id_whole_number);
    expect(detailsRobot.errorFor(NetworkField.symbol), S.current.symbol_format);

    await detailsRobot.enterField(NetworkField.failoverUrl, "");

    // A plain http RPC is refused before anything is contacted
    await detailsRobot.fillForm(
      name: name,
      rpcUrl: "http://ethereum-sepolia-rpc.publicnode.com",
      chainId: "$chainId",
      symbol: symbol,
    );

    await detailsRobot.saveExpectingError(NetworkField.rpcUrl);

    expect(detailsRobot.errorFor(NetworkField.rpcUrl), S.current.url_must_be_https);

    // A built-in chain ID is refused
    await detailsRobot.enterField(NetworkField.rpcUrl, rpcUrl);
    await detailsRobot.enterField(NetworkField.chainId, "1");

    await detailsRobot.saveExpectingError(NetworkField.chainId);

    expect(
      detailsRobot.errorFor(NetworkField.chainId),
      S.current.chain_id_used_by_builtin("1", "Ethereum"),
    );

    // A chain ID the RPC does not answer with is refused on the RPC field
    await detailsRobot.enterField(NetworkField.chainId, "$unlistedChainId");

    await detailsRobot.saveExpectingError(NetworkField.rpcUrl);

    expect(
      detailsRobot.errorFor(NetworkField.rpcUrl),
      S.current.rpc_field_chain_id_mismatch("$chainId", "$unlistedChainId"),
    );

    // The right chain ID saves, eth_chainId and eth_blockNumber are checked against the RPC
    await detailsRobot.enterField(NetworkField.chainId, "$chainId");

    await detailsRobot.saveExpectingClose();

    await manageRobot.isDisplayed();
    await manageRobot.search("Sepolia");
    await manageRobot.waitForRow(chainId);

    expect(manageRobot.isEnabled(chainId), true, reason: "A saved manual network starts on");

    await manageRobot.clearSearch();

    // The same chain ID and name cannot be added twice
    await manageRobot.openAddManually();
    await detailsRobot.isDisplayed();

    await detailsRobot.fillForm(name: name, rpcUrl: rpcUrl, chainId: "$chainId", symbol: symbol);

    await detailsRobot.saveExpectingError(NetworkField.chainId);

    expect(
      detailsRobot.errorFor(NetworkField.chainId),
      S.current.chain_id_used_by_network("$chainId", name),
    );
    expect(detailsRobot.errorFor(NetworkField.name), S.current.network_name_exists(name));

    await detailsRobot.closeForm();
    await manageRobot.isDisplayed();

    // A network with no wallets deletes through the warning, Cancel keeps it
    await evmNetworkFlows.openNetworkDetails(chainId, searchQuery: "Sepolia");

    expect(detailsRobot.isDeleteShown, true);
    expect(detailsRobot.isDeleteEnabled, true);
    expect(detailsRobot.isReadOnly(NetworkField.chainId), false);

    await detailsRobot.tapDelete();

    expect(detailsRobot.deleteWarningMessage(), S.current.delete_network_warning(name));

    await detailsRobot.cancelDelete();

    expect(detailsRobot.isShowing, true, reason: "Cancel on the delete warning closed the form");

    await detailsRobot.tapDelete();
    await detailsRobot.confirmDelete();

    await manageRobot.isDisplayed();

    expect(
      await manageRobot.pumpUntil(() => !manageRobot.hasRow(chainId)),
      true,
      reason: "The deleted network is still listed",
    );

    await manageRobot.clearSearch();

    await evmNetworkFlows.addNetworkManually(
      name: name,
      rpcUrl: rpcUrl,
      chainId: chainId,
      symbol: symbol,
    );

    await manageRobot.goBackToPicker();

    expect(await pickerRobot.waitForAddedNetworkRow(chainId, present: true), true);

    // Disabling the only added network takes it out of the picker and brings the disclaimer back
    await pickerRobot.openManageAddedNetworks();
    await manageRobot.isDisplayed();

    await evmNetworkFlows.disableNetwork(chainId, searchQuery: "Sepolia");

    await manageRobot.goBackToPicker();

    expect(
      await pickerRobot.waitForAddedNetworkRow(chainId, present: false),
      true,
      reason: "A disabled network is still offered in the picker",
    );
    expect(pickerRobot.hasAddEvmNetworksRow, true);
    expect(pickerRobot.hasManageAddedNetworksRow, false);

    await pickerRobot.openAddEvmNetworks();
    await disclaimerRobot.isDisplayed();
    await disclaimerRobot.tapContinue();
    await manageRobot.isDisplayed();

    await evmNetworkFlows.enableNetwork(chainId, searchQuery: "Sepolia");

    await manageRobot.goBackToPicker();

    expect(await pickerRobot.waitForAddedNetworkRow(chainId, present: true), true);

    await evmNetworkFlows.createWalletOnAddedNetwork(chainId, walletName: walletName);

    await homePageRobot.isDisplayed();

    final wallet = getIt.get<AppStore>().wallet!;

    expect(wallet.name, walletName);
    expect(wallet.type, WalletType.evm);
    expect(wallet.walletInfo.chainId, chainId);
    expect(wallet.currency.title, symbol);

    await evmNetworkFlows.confirmDashboardShowsNetwork(name, symbol);

    // With a wallet the core fields lock, Delete is refused and so is Disable
    await evmNetworkFlows.openCreatePickerFromWalletList();
    await pickerRobot.openManageAddedNetworks();
    await manageRobot.isDisplayed();

    await evmNetworkFlows.openNetworkDetails(chainId, searchQuery: "Sepolia");

    for (final field in [NetworkField.rpcUrl, NetworkField.chainId, NetworkField.symbol]) {
      expect(
        detailsRobot.isReadOnly(field),
        true,
        reason: "${field.name} is editable on a network that has a wallet",
      );
    }

    expect(detailsRobot.isReadOnly(NetworkField.name), false);
    expect(detailsRobot.hasNodesManagedNote, true);
    expect(detailsRobot.isDeleteEnabled, false, reason: "Delete is offered while a wallet uses it");
    expect(detailsRobot.deleteRefusedText, S.current.network_used_cannot_delete(name, "1", "0"));

    await detailsRobot.closeForm();
    await manageRobot.isDisplayed();

    await manageRobot.search("Sepolia");
    await manageRobot.waitForRow(chainId);
    await manageRobot.tapToggle(chainId);

    expect(await manageRobot.waitForRefusal(), S.current.network_used_cannot_disable(name, "1"));

    await manageRobot.dismissRefusal();

    expect(await manageRobot.pumpUntil(() => manageRobot.isEnabled(chainId) == true), true);
  });
}
