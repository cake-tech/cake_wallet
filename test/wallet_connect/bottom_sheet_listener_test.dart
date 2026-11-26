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

  testWidgets("a sheet queued during the first frame is shown once", (tester) async {
    final service = BottomSheetServiceImpl();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(service.queueBottomSheet(widget: const Text("first frame")));
    });

    await tester.pumpWidget(
      MaterialApp(
        home: BottomSheetListener(
          bottomSheetService: service,
          child: const Scaffold(body: SizedBox()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("first frame"), findsOneWidget);
  });

  testWidgets("a queued sheet is shown once when the dashboard is rebuilt under it", (
    tester,
  ) async {
    final service = BottomSheetServiceImpl();
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        onGenerateRoute: (settings) => MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => BottomSheetListener(
            bottomSheetService: service,
            child: const Scaffold(body: SizedBox()),
          ),
        ),
      ),
    );
    final answers = <Object?>[];
    unawaited(service.queueBottomSheet(widget: const Text("request one")));
    unawaited(service.queueBottomSheet(widget: const Text("request two")).then(answers.add));
    await tester.pumpAndSettle();

    unawaited(navigatorKey.currentState!.pushNamedAndRemoveUntil("/", (route) => false));
    await tester.pumpAndSettle();
    expect(find.text("request two"), findsOneWidget);

    Navigator.of(tester.element(find.text("request two"))).pop("answer two");
    await tester.pumpAndSettle();

    expect(find.text("request two"), findsNothing);
    expect(answers, ["answer two"]);
    expect(service.currentSheet.value, isNull);
  });

  testWidgets("nothing is shown while the queue is on hold, the sheet shows once on release", (
    tester,
  ) async {
    final service = BottomSheetServiceImpl()..isOnHold.value = true;
    await tester.pumpWidget(
      MaterialApp(
        home: BottomSheetListener(
          bottomSheetService: service,
          child: const Scaffold(body: SizedBox()),
        ),
      ),
    );
    final answers = <Object?>[];
    unawaited(service.queueBottomSheet(widget: const Text("held")).then(answers.add));
    await tester.pumpAndSettle();
    expect(find.text("held"), findsNothing);
    expect(answers, isEmpty);

    service.isOnHold.value = false;
    await tester.pumpAndSettle();
    expect(find.text("held"), findsOneWidget);

    Navigator.of(tester.element(find.text("held"))).pop("answer");
    await tester.pumpAndSettle();
    expect(answers, ["answer"]);
  });

  testWidgets("a hold that starts under a shown sheet keeps the next one queued", (tester) async {
    final service = BottomSheetServiceImpl();
    await tester.pumpWidget(
      MaterialApp(
        home: BottomSheetListener(
          bottomSheetService: service,
          child: const Scaffold(body: SizedBox()),
        ),
      ),
    );
    unawaited(service.queueBottomSheet(widget: const Text("shown before the hold")));
    unawaited(service.queueBottomSheet(widget: const Text("queued behind it")));
    await tester.pumpAndSettle();

    service.isOnHold.value = true;
    Navigator.of(tester.element(find.text("shown before the hold"))).pop();
    await tester.pumpAndSettle();
    expect(find.text("queued behind it"), findsNothing);

    service.isOnHold.value = false;
    await tester.pumpAndSettle();
    expect(find.text("queued behind it"), findsOneWidget);
  });
}
