import "dart:async";

import "package:cake_wallet/main.dart" as app;
import "package:flutter/foundation.dart";
import "package:flutter_test/flutter_test.dart";

import "benign_errors.dart";

// Async chains started by test taps bind to the test zone, so wallet networking still
// running after an interaction would fail the test with errors the app itself ignores.
// The body reports through a completer because an error cannot cross an error zone, and
// awaiting the guarded future directly hangs the test forever.
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

class AppLauncher {
  AppLauncher(this.tester);

  final WidgetTester tester;

  Future<void> launchApp({required String testKey}) async {
    // main() sets FlutterError.onError to the app's own handler, so anything installed
    // before it boots is thrown away.
    final bindingHandler = FlutterError.onError;

    await app.main(topLevelKey: ValueKey(testKey));

    _installTestErrorHandler(bindingHandler);

    await tester.pump(const Duration(seconds: 2));
  }

  // The app's handler is async and awaits on its first line, so it returns before
  // recording anything. The test framework reports an uncaught async error and then
  // asserts that reporting recorded it, turning every background error into an unreadable
  // binding assertion instead of the actual failure.
  void _installTestErrorHandler(FlutterExceptionHandler? bindingHandler) {
    FlutterError.onError = (details) {
      // Errors arriving on that path always go back to the binding, BaseRobot clears the
      // benign ones afterwards.
      final reportedByTestFramework = details.library == "Flutter test framework";

      if (!reportedByTestFramework && isBenignError(details.exceptionAsString())) {
        debugPrint("Ignoring benign error: ${details.exceptionAsString()}");
        return;
      }

      bindingHandler?.call(details);
    };
  }
}
