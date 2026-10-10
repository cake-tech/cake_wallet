import "dart:async";

import "package:cake_wallet/src/screens/wallet_connect/services/bottom_sheet_service.dart";
import "package:cake_wallet/src/screens/wallet_connect/widgets/bottom_sheet/bottom_sheet_listener_widget.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  testWidgets("a sheet queued while no listener is mounted shows once one mounts", (tester) async {
    final service = BottomSheetServiceImpl();
    final pending = service.queueBottomSheet(widget: const Text("queued while away"));

    await tester.pumpWidget(
      MaterialApp(
        home: BottomSheetListener(
          bottomSheetService: service,
          child: const Scaffold(body: SizedBox()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("queued while away"), findsOneWidget);

    Navigator.of(tester.element(find.text("queued while away"))).pop();
    await tester.pumpAndSettle();
    await pending;
    expect(service.currentSheet.value, isNull);
  });

  testWidgets("later sheets still render after one was queued while away", (tester) async {
    final service = BottomSheetServiceImpl();
    unawaited(service.queueBottomSheet(widget: const Text("first")));

    await tester.pumpWidget(
      MaterialApp(
        home: BottomSheetListener(
          bottomSheetService: service,
          child: const Scaffold(body: SizedBox()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.text("first"))).pop();
    await tester.pumpAndSettle();

    unawaited(service.queueBottomSheet(widget: const Text("second")));
    await tester.pumpAndSettle();
    expect(find.text("second"), findsOneWidget);
  });
}
