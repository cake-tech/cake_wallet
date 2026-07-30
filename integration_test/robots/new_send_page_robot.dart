import "package:cake_wallet/new-ui/pages/send_page.dart";
import "package:cake_wallet/new-ui/widgets/send_page/send_confirm_sheet.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

import "../core/base_robot.dart";

/// Drives the new UI send sheet.
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

  /// Drags the confirm swiper thumb across the screen to broadcast the transaction.
  ///
  /// The swiper only shows once the transaction is created, which is network bound.
  Future<void> swipeToConfirm({Duration timeout = const Duration(seconds: 90)}) async {
    final finder = find.byKey(ValueKey("send_page_confirm_swiper_key"));

    await pumpUntilFound(finder, timeout: timeout);

    final width = tester.view.physicalSize.width / tester.view.devicePixelRatio;
    await tester.drag(finder.first, Offset(width, 0));

    await tester.pump(const Duration(milliseconds: 500));
  }

  /// Waits until the broadcast went through, the confirm sheet shows its committed state.
  Future<void> confirmTransactionCommitted({
    Duration timeout = const Duration(minutes: 3),
  }) async {
    await pumpUntilFound(find.byType(TransactionCommittedScreenActionButton), timeout: timeout);
  }

  // The keys sit on the input wrapper widgets, the editable field is a descendant.
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
