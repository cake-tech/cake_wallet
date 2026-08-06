import "dart:async";

import "package:cake_wallet/main.dart" as app;
import "package:flutter/foundation.dart";
import "package:flutter_test/flutter_test.dart";

import "benign_errors.dart";

/// testWidgets with background async errors contained.
///
/// Async chains started by test taps bind to the test zone, so wallet networking that
/// keeps running after an interaction would otherwise fail the test with errors the
/// production app deliberately ignores. Body failures are handed back across the zone
/// boundary through a completer, an error cannot cross error zones on its own and
/// awaiting the guarded future directly would hang the test forever.
void integrationTest(String description, Future<void> Function(WidgetTester tester) body) {
  testWidgets(description, (tester) async {
    final completer = Completer<void>();

    await runZonedGuarded(() async {
      try {
        await body(tester);

        if (!completer.isCompleted) {
          completer.complete();
        }
      } catch (error, stack) {
        // Awaited failures, assertion failures included, must fail the test normally.
        if (!completer.isCompleted) {
          completer.completeError(error, stack);
        }
      }
    }, (error, stack) {
      debugPrint("Ignoring background async error: $error");
    });

    await completer.future;
  });
}

/// Boots the real app inside an integration test and installs the shared error policy.
class AppLauncher {
  AppLauncher(this.tester);

  final WidgetTester tester;

  Future<void> launchApp({required String testKey}) async {
    // Captured before the app boots, main() replaces FlutterError.onError with the app's
    // own handler so anything installed here beforehand is thrown away.
    final bindingHandler = FlutterError.onError;

    await app.main(topLevelKey: ValueKey(testKey));

    _installTestErrorHandler(bindingHandler);

    await tester.pump(const Duration(seconds: 2));
  }

  /// Replaces the app's error handler with one the test framework can work with.
  ///
  /// The app's handler is async and awaits on its first line, so it returns before
  /// recording anything. The test framework reports an uncaught async error and then
  /// asserts that reporting recorded it, which turns every background error into an
  /// unreadable binding assertion instead of the actual failure.
  void _installTestErrorHandler(FlutterExceptionHandler? bindingHandler) {
    FlutterError.onError = (details) {
      // The test framework asserts right after it reports, so errors arriving on that
      // path always go back to the binding. BaseRobot clears the benign ones afterwards.
      final reportedByTestFramework = details.library == "Flutter test framework";

      if (!reportedByTestFramework && isBenignError(details.exceptionAsString())) {
        debugPrint("Ignoring benign error: ${details.exceptionAsString()}");
        return;
      }

      bindingHandler?.call(details);
    };
  }
}
