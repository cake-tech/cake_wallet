import "package:cake_wallet/new-ui/pages/send_page.dart";
import "package:cake_wallet/new-ui/widgets/confirm_swiper.dart";
import "package:cake_wallet/new-ui/widgets/send_page/send_confirm_bottom_widget.dart";
import "package:cake_wallet/new-ui/widgets/send_page/send_confirm_sheet.dart";
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

  Future<void> tapSendButton() async {
    await tapByKey("send_page_send_button_key");
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

  // The swiper is the point of no return, it is only built once the wallet has produced a
  // real transaction. Waiting for it and requiring it never to arrive is the assertion that
  // holds whatever the screen does meanwhile, still syncing, still building, or given up.
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

  Future<void> expectSendFailed({Duration timeout = const Duration(seconds: 90)}) async {
    await pumpUntilFound(find.byType(TransactionErrorActions), timeout: timeout);

    expect(
      find.byType(ConfirmSwiper),
      findsNothing,
      reason: "The send failed but the screen still offered to broadcast it",
    );
  }

  Future<void> _enterTextInInput(String inputKey, String text) async {
    // The keys sit on the input wrapper widgets, the editable field is a descendant.
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
