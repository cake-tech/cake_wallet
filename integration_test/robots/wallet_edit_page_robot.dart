import "package:cake_wallet/src/screens/wallet/wallet_edit_page.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

import "../core/base_robot.dart";

class WalletEditPageRobot extends BaseRobot {
  WalletEditPageRobot(super.tester);

  @override
  Future<void> isDisplayed() async {
    await isSpecificPage<WalletEditPage>();
  }

  Future<void> enterName(String name) async {
    final input = find.byKey(const ValueKey("wallet_edit_page_name_input_key"));

    await pumpUntilFound(input);

    final field = find.descendant(of: input, matching: find.byType(EditableText));

    await tester.enterText(field.first, name);

    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> save() async {
    await tapByKey("wallet_edit_page_save_button_key");
  }

  Future<void> tapDelete() async {
    await tapByKey("wallet_edit_page_delete_button_key");
  }

  Future<void> confirmDelete() async {
    await tapByKey("wallet_edit_page_confirm_delete_button_key");
  }

  Future<void> expectNameTakenRefusal() async {
    await pumpUntilFound(find.byKey(const ValueKey("wallet_edit_page_name_taken_ok_button_key")));

    hasType<WalletEditPage>();
  }

  Future<void> dismissNameTakenRefusal() async {
    await tapByKey("wallet_edit_page_name_taken_ok_button_key");

    await settle();
  }
}
