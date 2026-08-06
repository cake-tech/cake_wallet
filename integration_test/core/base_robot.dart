import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";

import "benign_errors.dart";

abstract class BaseRobot {
  BaseRobot(this.tester);

  final WidgetTester tester;

  Future<void> isDisplayed();

  // Wallet networking keeps running under every screen and the test framework fails the
  // test at teardown with anything it threw, so the failures the app itself ignores have
  // to be cleared as the test goes.
  void drainBackgroundErrors() {
    final Object? pending = tester.takeException();

    if (pending == null) {
      return;
    }

    if (isBenignError(pending.toString())) {
      tester.printToConsole("Ignoring benign background error: $pending");
      return;
    }

    throw TestFailure("Unhandled background error: $pending");
  }

  Future<void> _pumpStep(Duration step) async {
    await tester.pump(step);

    drainBackgroundErrors();
  }

  Future<void> pumpUntilFound(
    Finder finder, {
    Duration timeout = const Duration(seconds: 30),
    Duration step = const Duration(milliseconds: 100),
  }) async {
    final endTime = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(endTime)) {
      await _pumpStep(step);

      if (tester.any(finder)) {
        return;
      }
    }

    await takeScreenshot("${runtimeType}_pump_until_found_timeout");
    throw TestFailure("Widget not found after ${timeout.inSeconds}s: $finder");
  }

  Future<void> pumpUntilGone(
    Finder finder, {
    Duration timeout = const Duration(seconds: 30),
    Duration step = const Duration(milliseconds: 100),
  }) async {
    final endTime = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(endTime)) {
      await _pumpStep(step);

      if (!tester.any(finder)) {
        return;
      }
    }

    await takeScreenshot("${runtimeType}_pump_until_gone_timeout");
    throw TestFailure("Widget still present after ${timeout.inSeconds}s: $finder");
  }

  Future<void> tapByKey(String key, {Duration timeout = const Duration(seconds: 30)}) async {
    final finder = find.byKey(ValueKey(key));

    await pumpUntilFound(finder, timeout: timeout);

    // A tap during a route transition lands on the animating overlay instead of the widget.
    await settle(max: const Duration(seconds: 2));

    await tester.tap(finder.first, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> tapWhenVisible(
    Finder finder, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    await pumpUntilFound(finder, timeout: timeout);

    await settle(max: const Duration(seconds: 2));

    await tester.tap(finder.first, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> enterTextByKey(String key, String text) async {
    final finder = find.byKey(ValueKey(key));

    await pumpUntilFound(finder);

    await tester.enterText(finder.first, text);
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> scrollUntilVisibleByKey(
    String itemKey,
    String scrollableKey, {
    double scrollStep = 300,
  }) async {
    final itemFinder = find.byKey(ValueKey(itemKey));

    // The item can already be on screen, no scrolling needed then.
    if (tester.any(itemFinder)) {
      return;
    }

    final scrollableFinder = find.descendant(
      of: find.byKey(ValueKey(scrollableKey)),
      matching: find.byType(Scrollable),
    );

    await pumpUntilFound(scrollableFinder.first);

    await tester.scrollUntilVisible(
      itemFinder,
      scrollStep,
      scrollable: scrollableFinder.first,
      maxScrolls: 50,
    );

    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<bool> pumpUntil(
    bool Function() condition, {
    Duration timeout = const Duration(seconds: 30),
    Duration step = const Duration(milliseconds: 100),
  }) async {
    final endTime = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(endTime)) {
      await _pumpStep(step);

      if (condition()) {
        return true;
      }
    }

    return false;
  }

  // The deepest navigator is the one closest to what is on screen.
  Future<void> goBack() async {
    final navigator = tester.state<NavigatorState>(find.byType(Navigator).last);
    navigator.pop();

    await tester.pump(const Duration(milliseconds: 500));
  }

  // Modal sheets are pushed onto the root navigator.
  Future<void> dismissModal() async {
    final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
    navigator.pop();

    await tester.pump(const Duration(milliseconds: 500));
  }

  // Bounded instead of pumpAndSettle, the dashboard animates forever and never settles.
  Future<void> settle({Duration max = const Duration(seconds: 3)}) async {
    final endTime = DateTime.now().add(max);

    while (DateTime.now().isBefore(endTime)) {
      await _pumpStep(const Duration(milliseconds: 100));

      if (!tester.binding.hasScheduledFrame) {
        return;
      }
    }
  }

  // Waits for the page widget to mount, screens that decrypt keys or unlock a wallet take
  // much longer on a ci emulator than on a dev machine.
  Future<void> isSpecificPage<T>({Duration timeout = const Duration(seconds: 30)}) async {
    await pumpUntilFound(find.byType(T), timeout: timeout);

    hasType<T>();
  }

  Future<void> swipePage({bool swipeRight = true}) async {
    await tester.drag(find.byType(PageView), Offset(swipeRight ? -300 : 300, 0));

    await settle();
  }

  bool isKeyPresent(String key) => tester.any(find.byKey(ValueKey(key)));

  void hasValueKey(String key) {
    expect(find.byKey(ValueKey(key)), findsOneWidget);
  }

  void hasType<T>() {
    expect(find.byType(T), findsOneWidget);
  }

  void hasText(String text, {bool isVisible = true}) {
    expect(find.text(text), isVisible ? findsOneWidget : findsNothing);
  }

  void hasTextAtLeastOnce(String text, {bool isVisible = true}) {
    expect(find.text(text), isVisible ? findsAny : findsNothing);
  }

  String? textByKey(String key) {
    final finder = find.byKey(ValueKey(key));

    if (!tester.any(finder)) {
      return null;
    }

    return tester.widget<Text>(finder.first).data;
  }

  // Screenshots are diagnostics, a failed one must never be what fails the test.
  Future<void> takeScreenshot(String name) async {
    try {
      final binding = tester.binding;

      if (binding is IntegrationTestWidgetsFlutterBinding) {
        await binding.takeScreenshot(name);
      }
    } catch (e) {
      tester.printToConsole("Screenshot $name failed: $e");
    }
  }
}
