import "package:cake_wallet/new-ui/pages/receive_page.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

import "../core/base_robot.dart";

class NewReceivePageRobot extends BaseRobot {
  NewReceivePageRobot(super.tester);

  @override
  Future<void> isDisplayed() async {
    await pumpUntilFound(find.byType(NewReceivePage));
  }

  Future<void> confirmAddressMatches(String expected) async {
    final wanted = _normalise(expected);

    await pumpUntilFound(find.byKey(const ValueKey("receive_page_address_key")));

    final matched = await pumpUntil(() => _renderedAddress() == wanted);

    expect(
      matched,
      true,
      reason: "Receive page should show $wanted but showed ${_renderedAddress()}",
    );
  }

  String _normalise(String address) =>
      address.replaceAll("bitcoincash:", "").replaceAll(RegExp(r"\s"), "");

  String? _renderedAddress() {
    final root = find.byKey(const ValueKey("receive_page_address_key"));

    if (!tester.any(root)) {
      return null;
    }

    final rich = find.descendant(of: root, matching: find.byType(RichText));

    if (tester.any(rich)) {
      final text = _normalise(tester.widget<RichText>(rich.first).text.toPlainText());

      if (text.isNotEmpty) {
        return text;
      }
    }

    final plain = find.descendant(of: root, matching: find.byType(Text));

    if (tester.any(plain)) {
      return _normalise(tester.widget<Text>(plain.first).data ?? "");
    }

    return null;
  }
}
