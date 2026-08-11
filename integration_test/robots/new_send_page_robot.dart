import "package:cake_wallet/new-ui/pages/send_page.dart";
import "package:cake_wallet/new-ui/widgets/confirm_swiper.dart";
import "package:cake_wallet/new-ui/widgets/send_page/send_confirm_bottom_widget.dart";
import "package:cake_wallet/new-ui/widgets/send_page/send_confirm_sheet.dart";
import "package:cake_wallet/view_model/send/send_view_model.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

import "../core/base_robot.dart";

class NewSendPageRobot extends BaseRobot {
  NewSendPageRobot(super.tester);

  @override
  Future<void> isDisplayed() async {
    await pumpUntilFound(find.byType(NewSendPage));
  }

  Future<void> enterAddress(String address) async {
    await _enterTextInInput("send_page_address_input_key", address);
  }

  Future<void> enterAmount(String amount) async {
    await _enterTextInInput("send_page_amount_input_key", amount);
  }

  Future<void> pickContactFromAddressBook(String contactName) async {
    await tapByKey("send_page_address_book_button_key");

    // The picker opens on the wallets tab, saved contacts are on the one after it.
    final tabs = find.byType(Tab);

    await pumpUntilFound(tabs);

    await tester.tap(tabs.at(1));

    await settle();

    // Opened from send the list is not editable, so a tap picks the contact instead of
    // opening it for editing.
    final contactFinder = find.byKey(ValueKey(contactName));

    await pumpUntilFound(contactFinder);

    await tester.tap(contactFinder.first);

    await pumpUntilGone(contactFinder);
  }

  String enteredAddress() {
    final inputFinder = find.byKey(const ValueKey("send_page_address_input_key"));

    final field = find.descendant(of: inputFinder, matching: find.byType(EditableText));

    return tester.widget<EditableText>(field.first).controller.text;
  }

  Future<void> tapSendButton() async {
    await tapByKey("send_page_send_button_key");
  }

  Future<void> tapSendButtonWhenReady({Duration timeout = const Duration(minutes: 10)}) async {
    final ready = await pumpUntil(() => _sendViewModel()?.isReadyForSend ?? false, timeout: timeout);

    expect(
      ready,
      true,
      reason: "The wallet never became ready to send within ${timeout.inMinutes}m, "
          "so the send button stayed disabled",
    );

    await tapSendButton();
  }

  // Tapping send pops the send page and opens the confirm sheet in its place, so whichever
  // of the two is up is the one holding the view model
  SendViewModel? _sendViewModel() {
    final sheet = find.byType(SendConfirmSheet);

    if (tester.any(sheet)) {
      return tester.widget<SendConfirmSheet>(sheet.first).sendViewModel;
    }

    final page = find.byType(NewSendPage);

    if (tester.any(page)) {
      return tester.widget<NewSendPage>(page.first).sendViewModel;
    }

    return null;
  }

  Future<void> swipeToConfirm({Duration timeout = const Duration(seconds: 90)}) async {
    final finder = find.byKey(const ValueKey("send_page_confirm_swiper_key"));

    await pumpUntilFound(finder, timeout: timeout);

    final width = tester.view.physicalSize.width / tester.view.devicePixelRatio;
    await tester.drag(finder.first, Offset(width, 0));

    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<void> confirmTransactionCommitted({
    Duration timeout = const Duration(minutes: 3),
  }) async {
    await pumpUntilFound(find.byType(TransactionCommittedScreenActionButton), timeout: timeout);
  }

  Future<void> expectNoTransactionBuilt({
    Duration window = const Duration(seconds: 15),
  }) async {
    final offered = await pumpUntil(
      () => tester.any(find.byType(ConfirmSwiper)),
      timeout: window,
    );

    expect(
      offered,
      false,
      reason: "The send screen offered to broadcast a transaction it should have refused",
    );
  }

  Future<void> confirmTransactionBuilt({
    Duration timeout = const Duration(seconds: 90),
  }) async {
    final built = await pumpUntil(() => tester.any(find.byType(ConfirmSwiper)), timeout: timeout);

    if (built) {
      return;
    }

    final model = _sendViewModel();
    final available = model?.wallet.balance.values
        .map((balance) => balance.available)
        .where((amount) => amount.sign > 0)
        .join(", ");

    // A build that failed swaps the swiper for the error, which carries the only wording
    // that says what the chain actually objected to
    final errorFinder = find.byType(TransactionErrorActions);
    final buildError = tester.any(errorFinder)
        ? tester.widget<TransactionErrorActions>(errorFinder.first).errorText
        : null;

    fail(
      "No confirm sheet after ${timeout.inSeconds}s. "
      "state=${model?.state.runtimeType}, "
      "wallet holds ${available == null || available.isEmpty ? "nothing" : available}"
      "${buildError == null ? "" : ", the build failed with: $buildError"}",
    );
  }

  String enteredAmount() {
    final inputFinder = find.byKey(const ValueKey("send_page_amount_input_key"));

    if (!tester.any(inputFinder)) {
      return "unknown";
    }

    final field = find.descendant(of: inputFinder, matching: find.byType(EditableText));

    return tester.widget<EditableText>(field.first).controller.text;
  }

  Future<void> expectSendFailed({Duration timeout = const Duration(seconds: 90)}) async {
    await pumpUntilFound(find.byType(TransactionErrorActions), timeout: timeout);

    expect(
      find.byType(ConfirmSwiper),
      findsNothing,
      reason: "The send failed but the screen still offered to broadcast it",
    );
  }

  Future<void> _enterTextInInput(String inputKey, String text) async {
    final inputFinder = find.byKey(ValueKey(inputKey));

    await pumpUntilFound(inputFinder);

    final fieldFinder = find.descendant(
      of: inputFinder,
      matching: find.byType(EditableText),
    );

    await tester.enterText(fieldFinder.first, text);
    await tester.pump(const Duration(milliseconds: 300));
  }
}
