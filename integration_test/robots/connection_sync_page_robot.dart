import "package:cake_wallet/entities/fiat_api_mode.dart";
import "package:cake_wallet/src/screens/settings/connection_sync_page.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

import "../core/base_robot.dart";

class ConnectionSyncPageRobot extends BaseRobot {
  ConnectionSyncPageRobot(super.tester);

  @override
  Future<void> isDisplayed() async {
    await isSpecificPage<ConnectionSyncPage>();
  }

  Future<void> setFiatApiMode(FiatApiMode mode) async {
    await tapByKey("fiat_api");

    // The mode already in use is drawn by a different branch of the picker, so it carries a
    // key of its own.
    final unselected = find.byKey(ValueKey("picker_items_index_${mode.title}_button_key"));
    final selected =
        find.byKey(ValueKey("picker_items_index_${mode.title}_selected_item_button_key"));

    await pumpUntil(() => tester.any(unselected) || tester.any(selected));

    await tester.tap(tester.any(unselected) ? unselected : selected);

    await settle();
  }

  void hasFiatApiMode(FiatApiMode mode) {
    expect(
      find.descendant(
        of: find.byKey(const ValueKey("fiat_api")),
        matching: find.text(mode.title),
      ),
      findsOneWidget,
      reason: "The fiat api row does not show ${mode.title}",
    );
  }
}
