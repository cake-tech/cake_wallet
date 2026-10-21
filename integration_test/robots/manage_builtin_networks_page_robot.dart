import "package:cake_wallet/new-ui/pages/wallet_network/manage_builtin_networks_page.dart";
import "package:cake_wallet/src/widgets/alert_with_one_action.dart";
import "package:cake_wallet/src/widgets/new_list_row/list_item_checkbox_widget.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

import "../core/base_robot.dart";

class ManageBuiltinNetworksPageRobot extends BaseRobot {
  ManageBuiltinNetworksPageRobot(super.tester);

  @override
  Future<void> isDisplayed() async {
    await isSpecificPage<ManageBuiltinNetworksPage>();
  }

  Finder _networkRow(WalletType type) =>
      find.byKey(ValueKey("manage_builtin_networks_${type.name}_row_key"));

  Future<void> _scrollIntoView(WalletType type) async {
    final scrollable = find.descendant(
      of: find.byKey(const ValueKey("manage_builtin_networks_scrollable_key")),
      matching: find.byType(Scrollable),
    );

    await pumpUntilFound(scrollable.first);

    await tester.scrollUntilVisible(
      _networkRow(type),
      200,
      scrollable: scrollable.first,
      maxScrolls: 30,
    );

    await settle(max: const Duration(seconds: 1));
  }

  bool isVisible(WalletType type) => tester.widget<ListItemCheckboxWidget>(_networkRow(type)).value;

  Future<void> toggle(WalletType type) async {
    await _scrollIntoView(type);

    await tester.tap(_networkRow(type), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> setVisible(WalletType type, {required bool visible}) async {
    await _scrollIntoView(type);

    if (isVisible(type) == visible) {
      return;
    }

    await toggle(type);

    final changed = await pumpUntil(() => isVisible(type) == visible);

    expect(changed, true, reason: "${type.name} did not become ${visible ? "visible" : "hidden"}");
  }

  Future<String> waitForRefusal() async {
    await pumpUntilFound(find.byType(AlertWithOneAction));

    return tester.widget<AlertWithOneAction>(find.byType(AlertWithOneAction)).alertContent;
  }

  Future<void> dismissRefusal() async {
    await tapByKey("manage_builtin_networks_refusal_ok_button_key");

    await pumpUntilGone(find.byType(AlertWithOneAction));
  }

  Future<void> goBackToPicker() async {
    await tapWhenVisible(
      find.descendant(
        of: find.byType(ManageBuiltinNetworksPage),
        matching: find.byIcon(Icons.arrow_back_ios_new),
      ),
    );

    await pumpUntilGone(find.byType(ManageBuiltinNetworksPage));
  }
}
