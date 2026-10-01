import "package:cake_wallet/core/wallet_network.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";

import "../../core/app_launcher.dart";
import "../../flows/evm_network_flows.dart";
import "../../robots/add_evm_networks_disclaimer_page_robot.dart";
import "../../robots/manage_builtin_networks_page_robot.dart";
import "../../robots/manage_evm_networks_page_robot.dart";
import "../../robots/wallet_network_page_robot.dart";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  integrationTest(
      "Hidden built-in networks leave the picker and the disclaimer gates Add EVM Networks",
      (tester) async {
    final appLauncher = AppLauncher(tester);
    final evmNetworkFlows = EvmNetworkFlows(tester);
    final pickerRobot = WalletNetworkPageRobot(tester);
    final builtinRobot = ManageBuiltinNetworksPageRobot(tester);
    final disclaimerRobot = AddEvmNetworksDisclaimerPageRobot(tester);
    final manageRobot = ManageEvmNetworksPageRobot(tester);

    await appLauncher.launchApp(testKey: "wallet_network_picker_test_app_key");

    await evmNetworkFlows.openCreatePickerAtOnboarding();

    expect(
      builtinNetworkTypes.contains(WalletType.evm),
      false,
      reason: "evm is a family of added networks and must never be a built-in row",
    );

    for (final type in builtinNetworkTypes) {
      expect(pickerRobot.hasBuiltinRow(type), true, reason: "${type.name} missing from picker");
    }

    // Hide one network, it leaves the picker and search can no longer find it
    await pickerRobot.openManageBuiltinNetworks();
    await builtinRobot.isDisplayed();

    await builtinRobot.setVisible(WalletType.ethereum, visible: false);

    await builtinRobot.goBackToPicker();
    await pickerRobot.isDisplayed();

    expect(
      await pickerRobot.waitForBuiltinRow(WalletType.ethereum, present: false),
      true,
      reason: "Hidden Ethereum is still offered in the picker",
    );
    expect(pickerRobot.hasBuiltinRow(WalletType.monero), true);

    await pickerRobot.search("Ethereum");

    expect(
      await pickerRobot.pumpUntil(() => pickerRobot.hasNoNetworksFound),
      true,
      reason: "Searching a hidden network should find nothing",
    );
    expect(
      pickerRobot.hasAddEvmNetworksRow,
      true,
      reason: "Add EVM Networks has to stay reachable when the search finds nothing",
    );

    await pickerRobot.clearSearch();

    // Showing it again puts it back
    await pickerRobot.openManageBuiltinNetworks();
    await builtinRobot.isDisplayed();

    await builtinRobot.setVisible(WalletType.ethereum, visible: true);

    await builtinRobot.goBackToPicker();

    expect(
      await pickerRobot.waitForBuiltinRow(WalletType.ethereum, present: true),
      true,
      reason: "Ethereum did not come back after being shown again",
    );

    // Hiding the last visible network is refused
    await pickerRobot.openManageBuiltinNetworks();
    await builtinRobot.isDisplayed();

    const keptVisible = WalletType.monero;

    for (final type in builtinNetworkTypes.where((type) => type != keptVisible)) {
      await builtinRobot.setVisible(type, visible: false);
    }

    await builtinRobot.toggle(keptVisible);

    final refusal = await builtinRobot.waitForRefusal();

    expect(refusal, S.current.at_least_one_network_visible);

    await builtinRobot.dismissRefusal();

    expect(
      builtinRobot.isVisible(keptVisible),
      true,
      reason: "The last visible network was hidden despite the refusal",
    );

    await builtinRobot.goBackToPicker();
    await pickerRobot.isDisplayed();

    expect(await pickerRobot.waitForBuiltinRow(WalletType.bitcoin, present: false), true);

    for (final type in builtinNetworkTypes) {
      expect(
        pickerRobot.hasBuiltinRow(type),
        type == keptVisible,
        reason: "With only ${keptVisible.name} visible the picker showed ${type.name} wrongly",
      );
    }

    // Cancel on the disclaimer returns to the picker with nothing added
    await pickerRobot.openAddEvmNetworks();
    await disclaimerRobot.isDisplayed();

    await disclaimerRobot.tapCancel();
    await pickerRobot.isDisplayed();

    expect(manageRobot.isShowing, false, reason: "Cancel opened Manage EVM Networks");
    expect(pickerRobot.hasAddEvmNetworksRow, true);
    expect(pickerRobot.hasManageAddedNetworksRow, false);

    // The disclaimer is shown again every time, Continue opens Manage EVM Networks
    await pickerRobot.openAddEvmNetworks();
    await disclaimerRobot.isDisplayed();

    await disclaimerRobot.tapContinue();
    await manageRobot.isDisplayed();

    await manageRobot.goBackToPicker();
    await pickerRobot.isDisplayed();

    expect(
      pickerRobot.hasAddEvmNetworksRow,
      true,
      reason: "Visiting Manage EVM Networks without enabling anything must not add a network",
    );
  });
}
