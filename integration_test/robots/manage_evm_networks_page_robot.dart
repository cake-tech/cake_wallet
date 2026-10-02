import "package:cake_wallet/new-ui/pages/wallet_network/manage_evm_networks_page.dart";
import "package:cake_wallet/src/widgets/alert_with_one_action.dart";
import "package:cake_wallet/src/widgets/standard_switch.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

import "../core/base_robot.dart";

class ManageEvmNetworksPageRobot extends BaseRobot {
  ManageEvmNetworksPageRobot(super.tester);

  @override
  Future<void> isDisplayed() async {
    await isSpecificPage<ManageEvmNetworksPage>();
  }

  bool get isShowing => tester.any(find.byType(ManageEvmNetworksPage));

  Finder _networkRow(int chainId) => find.byKey(ValueKey("manage_evm_networks_${chainId}_row_key"));

  Finder _networkToggle(int chainId) =>
      find.byKey(ValueKey("manage_evm_networks_${chainId}_toggle_key"));

  Future<void> search(String query) async {
    final field = find.descendant(
      of: find.byKey(const ValueKey("manage_evm_networks_search_field_key")),
      matching: find.byType(TextField),
    );

    await pumpUntilFound(field);

    await tester.enterText(field.first, query);
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<void> clearSearch() async {
    await search("");
  }

  bool hasRow(int chainId) => tester.any(_networkRow(chainId));

  Future<void> waitForRow(int chainId, {Duration timeout = const Duration(seconds: 30)}) async {
    await pumpUntilFound(_networkRow(chainId), timeout: timeout);
  }

  Future<bool> waitForNoMatch() =>
      pumpUntil(() => isKeyPresent("manage_evm_networks_no_networks_found_text_key"));

  bool get hasNoMatch => isKeyPresent("manage_evm_networks_no_networks_found_text_key");

  /// Null while the toggle shows its spinner
  bool? isEnabled(int chainId) {
    final toggle =
        find.descendant(of: _networkToggle(chainId), matching: find.byType(StandardSwitch));

    if (!tester.any(toggle)) {
      return null;
    }

    return tester.widget<StandardSwitch>(toggle.first).value;
  }

  Future<void> tapToggle(int chainId) async {
    await pumpUntilFound(_networkToggle(chainId));

    await tester.ensureVisible(_networkToggle(chainId));
    await settle(max: const Duration(seconds: 1));

    await tester.tap(_networkToggle(chainId), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 300));
  }

  /// Taps the toggle and waits for the RPC check, a refusal alert ends the wait early
  Future<void> setEnabled(int chainId, {required bool enabled}) async {
    await pumpUntilFound(_networkToggle(chainId));

    if (isEnabled(chainId) == enabled) {
      return;
    }

    await tapToggle(chainId);

    // Enabling runs eth_chainId and eth_blockNumber against up to four RPCs, 10 s per call
    final settled = await pumpUntil(
      () => isEnabled(chainId) == enabled || hasRefusal,
      timeout: const Duration(seconds: 90),
    );

    expect(settled, true, reason: "Chain $chainId toggle never settled");

    if (hasRefusal) {
      throw TestFailure("Toggling chain $chainId was refused: ${refusalMessage()}");
    }
  }

  bool get hasRefusal => tester.any(find.byType(AlertWithOneAction));

  String refusalMessage() =>
      tester.widget<AlertWithOneAction>(find.byType(AlertWithOneAction).first).alertContent;

  Future<String> waitForRefusal({Duration timeout = const Duration(seconds: 30)}) async {
    await pumpUntilFound(find.byType(AlertWithOneAction), timeout: timeout);

    return refusalMessage();
  }

  Future<void> dismissRefusal() async {
    await tapByKey("manage_evm_networks_refusal_ok_button_key");

    await pumpUntilGone(find.byType(AlertWithOneAction));
  }

  Future<void> openEdit(int chainId) async {
    final edit = find.byKey(ValueKey("manage_evm_networks_${chainId}_edit_button_key"));

    await pumpUntilFound(edit);

    await tester.ensureVisible(edit);

    await tapWhenVisible(edit);
  }

  Future<void> openAddManually() async {
    await tapByKey("manage_evm_networks_add_manually_button_key");
  }

  Future<void> goBackToPicker() async {
    await tapWhenVisible(
      find.descendant(
        of: find.byType(ManageEvmNetworksPage),
        matching: find.byIcon(Icons.arrow_back_ios_new),
      ),
    );

    await pumpUntilGone(find.byType(ManageEvmNetworksPage));
  }
}
