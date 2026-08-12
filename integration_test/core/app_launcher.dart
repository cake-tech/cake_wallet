import "dart:async";

import "package:cake_wallet/main.dart" as app;
import "package:flutter/foundation.dart";
import "package:flutter_test/flutter_test.dart";

import "benign_errors.dart";

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
    final bindingHandler = FlutterError.onError;

    await app.main(topLevelKey: ValueKey(testKey));

    _installTestErrorHandler(bindingHandler);

    await tester.pump(const Duration(seconds: 2));
  }

  void _installTestErrorHandler(FlutterExceptionHandler? bindingHandler) {
    FlutterError.onError = (details) {
      final reportedByTestFramework = details.library == "Flutter test framework";

      if (!reportedByTestFramework && isBenignError(details.exceptionAsString())) {
        debugPrint("Ignoring benign error: ${details.exceptionAsString()}");
        return;
      }

      bindingHandler?.call(details);
    };
  }
}
