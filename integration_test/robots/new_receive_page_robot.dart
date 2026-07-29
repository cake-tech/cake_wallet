import "package:cake_wallet/new-ui/pages/receive_page.dart";
import "package:flutter_test/flutter_test.dart";

import "../core/base_robot.dart";

/// Drives the new UI receive sheet.
class NewReceivePageRobot extends BaseRobot {
  NewReceivePageRobot(super.tester);

  @override
  Future<void> isDisplayed() async {
    await pumpUntilFound(find.byType(NewReceivePage));
  }

  /// Waits until the displayed address matches, the address derives shortly after opening.
  Future<void> confirmAddressMatches(String expected) async {
    final matched = await pumpUntil(() => _currentAddress() == expected);

    expect(
      matched,
      true,
      reason: "Receive address should be $expected but was ${_currentAddress()}",
    );
  }

  String? _currentAddress() {
    final finder = find.byType(NewReceivePage);

    if (!tester.any(finder)) {
      return null;
    }

    return tester.widget<NewReceivePage>(finder.first).addressListViewModel.uri.address;
  }
}
