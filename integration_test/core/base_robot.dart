import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";

/// Base class for all screen robots, holds the shared waiting and interaction primitives.
abstract class BaseRobot {
  BaseRobot(this.tester);

  final WidgetTester tester;

  /// Asserts that the robot's screen is currently displayed.
  Future<void> isDisplayed();

  /// Pumps frames until the finder matches, failing with a screenshot when the timeout passes.
  Future<void> pumpUntilFound(
    Finder finder, {
    Duration timeout = const Duration(seconds: 30),
    Duration step = const Duration(milliseconds: 100),
  }) async {
    final endTime = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(endTime)) {
      await tester.pump(step);

      if (tester.any(finder)) {
        return;
      }
    }

    await takeScreenshot("${runtimeType}_pump_until_found_timeout");
    throw TestFailure("Widget not found after ${timeout.inSeconds}s: $finder");
  }

  /// Pumps frames until the finder stops matching, for dismissing modals and spinners.
  Future<void> pumpUntilGone(
    Finder finder, {
    Duration timeout = const Duration(seconds: 30),
    Duration step = const Duration(milliseconds: 100),
  }) async {
    final endTime = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(endTime)) {
      await tester.pump(step);

      if (!tester.any(finder)) {
        return;
      }
    }

    await takeScreenshot("${runtimeType}_pump_until_gone_timeout");
    throw TestFailure("Widget still present after ${timeout.inSeconds}s: $finder");
  }

  /// Waits for the widget with the given key to appear, then taps it.
  Future<void> tapByKey(String key, {Duration timeout = const Duration(seconds: 30)}) async {
    final finder = find.byKey(ValueKey(key));

    await pumpUntilFound(finder, timeout: timeout);

    await tester.tap(finder.first, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 300));
  }

  /// Waits for the finder to match, then taps the first match.
  Future<void> tapWhenVisible(
    Finder finder, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    await pumpUntilFound(finder, timeout: timeout);

    await tester.tap(finder.first, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 300));
  }

  /// Waits for the text field with the given key to appear, then types into it.
  Future<void> enterTextByKey(String key, String text) async {
    final finder = find.byKey(ValueKey(key));

    await pumpUntilFound(finder);

    await tester.enterText(finder.first, text);
    await tester.pump(const Duration(milliseconds: 300));
  }

  /// Scrolls inside the scrollable with the given key until the item key becomes visible.
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

  /// Pumps until no more frames are scheduled, bounded because some screens animate forever.
  Future<void> settle({Duration max = const Duration(seconds: 3)}) async {
    final endTime = DateTime.now().add(max);

    while (DateTime.now().isBefore(endTime)) {
      await tester.pump(const Duration(milliseconds: 100));

      if (!tester.binding.hasScheduledFrame) {
        return;
      }
    }
  }

  bool isKeyPresent(String key) => tester.any(find.byKey(ValueKey(key)));

  void hasText(String text) {
    expect(find.text(text), findsWidgets);
  }

  /// Reads the content of the Text widget with the given key, null when it is not on screen.
  String? textByKey(String key) {
    final finder = find.byKey(ValueKey(key));

    if (!tester.any(finder)) {
      return null;
    }

    return tester.widget<Text>(finder.first).data;
  }

  /// Takes a screenshot without ever failing the test, screenshots are diagnostics only.
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
