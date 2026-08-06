import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

class CommonTestCases {
  CommonTestCases(this.tester);
  WidgetTester tester;

  Future<void> isSpecificPage<T>({Duration timeout = const Duration(seconds: 30)}) async {
    final finder = find.byType(T);

    // Routes that decrypt keys or unlock a wallet take much longer on a ci emulator than
    // on a dev machine, so wait for the page instead of asserting on the next frame.
    final endTime = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(endTime)) {
      await tester.pump(const Duration(milliseconds: 100));

      if (tester.any(finder)) {
        break;
      }
    }

    hasType<T>();
  }

  Future<void> tapItemByKey(
    String key, {
    bool shouldPumpAndSettle = true,
    int pumpDuration = 100,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final widgetFinder = find.byKey(ValueKey(key));

    final endTime = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(endTime)) {
      await tester.pump(const Duration(milliseconds: 100));

      if (tester.any(widgetFinder)) {
        break;
      }
    }

    expect(tester.any(widgetFinder), true, reason: 'Widget with key "$key" should be visible');

    final widget = widgetFinder.first;
    await tester.tap(widget, warnIfMissed: false);
    shouldPumpAndSettle
        ? await tester.pumpAndSettle(Duration(milliseconds: pumpDuration))
        : await tester.pump();
  }

  void hasText(String text, {bool hasWidget = true}) {
    final textWidget = find.text(text);
    expect(textWidget, hasWidget ? findsOneWidget : findsNothing);
  }

  void hasTextAtLestOnce(String text, {bool hasWidget = true}) {
    final textWidget = find.text(text);
    expect(textWidget, hasWidget ? findsAny : findsNothing);
  }

  void hasType<T>() {
    final typeWidget = find.byType(T);
    expect(typeWidget, findsOneWidget);
  }

  bool isKeyPresent(String key) {
    final typeWidget = find.byKey(ValueKey(key));
    return typeWidget.tryEvaluate();
  }

  void hasValueKey(String key) {
    final typeWidget = find.byKey(ValueKey(key));
    expect(typeWidget, findsOneWidget);
  }

  Future<void> swipePage({bool swipeRight = true}) async {
    await tester.drag(find.byType(PageView), Offset(swipeRight ? -300 : 300, 0));
    await tester.pumpAndSettle();
  }

  Future<void> goBack() async {
    tester.printToConsole("Routing back to previous screen");
    final NavigatorState navigator = tester.state(find.byType(Navigator));
    navigator.pop();
    await tester.pumpAndSettle();
  }

  Future<void> enterText(
    String text,
    String editableTextKey, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final editableTextWidget = find.byKey(ValueKey(editableTextKey));

    final endTime = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(endTime)) {
      await tester.pump(const Duration(milliseconds: 100));

      if (tester.any(editableTextWidget)) {
        break;
      }
    }

    await tester.enterText(editableTextWidget, text);

    await tester.pumpAndSettle();
  }

  Future<void> defaultSleepTime({int seconds = 2}) => Future.delayed(Duration(seconds: seconds));

  // Does nothing until the binding is set up for screenshots, BaseRobot.takeScreenshot is
  // the one that works.
  Future<void> takeScreenshots(String screenshotName) async {}
}
