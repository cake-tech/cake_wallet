import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class CommonTestCases {
  WidgetTester tester;
  CommonTestCases(this.tester);

  Future<void> isSpecificPage<T>() async {
    await tester.pumpAndSettle();
    hasType<T>();
  }

  Future<void> tapItemByKey(String key, {bool shouldPumpAndSettle = true}) async {
    final widget = find.byKey(ValueKey(key));
    await tester.tap(widget);
    shouldPumpAndSettle ? await tester.pumpAndSettle() : await tester.pump();
  }

  Future<void> tapItemByFinder(Finder finder, {bool shouldPumpAndSettle = true}) async {
    await tester.tap(finder);
    shouldPumpAndSettle ? await tester.pumpAndSettle() : await tester.pump();
  }

  void hasText(String text, {bool hasWidget = true}) {
    final textWidget = find.text(text);
    expect(textWidget, hasWidget ? findsOneWidget : findsNothing);
  }

  void hasType<T>() {
    final typeWidget = find.byType(T);
    expect(typeWidget, findsOneWidget);
  }

  void hasValueKey(String key) {
    final typeWidget = find.byKey(ValueKey(key));
    expect(typeWidget, findsOneWidget);
  }

  Future<void> swipePage({bool swipeRight = true}) async {
    await tester.drag(find.byType(PageView), Offset(swipeRight ? -300 : 300, 0));
    await tester.pumpAndSettle();
  }

  Future<void> swipeByPageKey({required String key, bool swipeRight = true}) async {
    await tester.drag(find.byKey(ValueKey(key)), Offset(swipeRight ? -300 : 300, 0));
    await tester.pumpAndSettle();
  }

  Future<void> goBack() async {
    tester.printToConsole('Routing back to previous screen');
    final NavigatorState navigator = tester.state(find.byType(Navigator));
    navigator.pop();
    await tester.pumpAndSettle();
  }

  Future<void> scrollUntilVisible(String childKey, String parentScrollableKey,
      {double delta = 300}) async {
    final scrollableWidget = find.descendant(
      of: find.byKey(Key(parentScrollableKey)),
      matching: find.byType(Scrollable),
    );

    final isAlreadyVisibile = isWidgetVisible(find.byKey(ValueKey(childKey)));

    if (isAlreadyVisibile) return;

    await tester.scrollUntilVisible(
      find.byKey(ValueKey(childKey)),
      delta,
      scrollable: scrollableWidget,
    );
  }

  bool isWidgetVisible(Finder finder) {
    try {
      final Element element = finder.evaluate().single;
      final RenderBox renderBox = element.renderObject as RenderBox;
      return renderBox.paintBounds
          .shift(renderBox.localToGlobal(Offset.zero))
          .overlaps(tester.binding.renderViews.first.paintBounds);
    } catch (e) {
      return false;
    }
  }

  Future<void> enterText(String text, String editableTextKey) async {
    final editableTextWidget = find.byKey(ValueKey((editableTextKey)));

    await tester.enterText(editableTextWidget, text);

    await tester.pumpAndSettle();
  }

  Future<void> defaultSleepTime({int seconds = 2}) async =>
      await Future.delayed(Duration(seconds: seconds));
}
