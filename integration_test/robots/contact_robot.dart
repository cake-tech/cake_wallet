import "package:cake_wallet/src/screens/contact/contact_list_page.dart";
import "package:cake_wallet/src/screens/contact/contact_page.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

import "../core/base_robot.dart";

class ContactRobot extends BaseRobot {
  ContactRobot(super.tester);

  @override
  Future<void> isDisplayed() async {
    await pumpUntilFound(find.byType(ContactListPage));
  }

  Future<void> openAddContact() async {
    await tapByKey("contact_list_page_add_contact_button_key");

    await pumpUntilFound(find.byType(ContactPage));
  }

  Future<void> enterName(String name) async {
    await enterTextByKey("contact_page_name_textfield_key", name);
  }

  Future<void> chooseCurrency(String currencyName) async {
    await tapByKey("contact_page_currency_picker_button_key");

    await tapByKey("picker_items_index_${currencyName}_button_key");

    await settle();
  }

  Future<void> enterAddress(String address) async {
    final input = find.byKey(const ValueKey("contact_page_address_input_key"));

    await pumpUntilFound(input);

    final field = find.descendant(of: input, matching: find.byType(EditableText));

    await tester.enterText(field.first, address);
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> save() async {
    await tapByKey("contact_page_save_button_key");

    await pumpUntilGone(find.byType(ContactPage));

    await settle();
  }

  void expectContactSaved(String name, String address) {
    final page = tester.widget<ContactListPage>(find.byType(ContactListPage));

    final saved = page.contactListViewModel.contacts.where((c) => c.name == name).toList();

    expect(saved, isNotEmpty, reason: "The contact $name was never saved");

    expect(
      saved.first.address,
      address,
      reason: "The address book stored a different address than it was given",
    );
  }
}
