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

  SendViewModel? _sendViewModel() {
    final finder = find.byType(NewSendPage);

    if (!tester.any(finder)) {
      return null;
    }

    return tester.widget<NewSendPage>(finder.first).sendViewModel;
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
    await pumpUntilFound(find.byType(ConfirmSwiper), timeout: timeout);
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
