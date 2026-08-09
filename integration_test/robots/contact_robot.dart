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

  // The currency has to be chosen before the address field is built at all, the form has no
  // way to validate an address until it knows which chain it is for.
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

  // Saving pops the form, so the form going away is what says the save was accepted. The
  // button sits disabled until the view model has a name, a currency and an address, so a tap
  // that changes nothing leaves us here.
  Future<void> save() async {
    await tapByKey("contact_page_save_button_key");

    await pumpUntilGone(find.byType(ContactPage));

    await settle();
  }

  // Asserts against the saved records rather than the rows, the list filters what it shows by
  // the currency in play. What matters is that the book kept the address it was handed, since
  // the whole point is pasting an address once and trusting it afterwards.
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
