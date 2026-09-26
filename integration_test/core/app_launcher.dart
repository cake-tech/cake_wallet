import "dart:async";

import "package:cake_wallet/main.dart" as app;
import "package:flutter/foundation.dart";
import "package:flutter_test/flutter_test.dart";

import "benign_errors.dart";

void integrationTest(String description, Future<void> Function(WidgetTester tester) body) {
  testWidgets(description, (tester) async {
    final completer = Completer<void>();

    final run = runZonedGuarded(() async {
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
      final kind = benignErrorKind(error.toString());

      if (kind != null) {
        debugPrint("Ignoring benign $kind background error: $error");
        return;
      }

      if (completer.isCompleted) {
        debugPrint("Background error after the test finished: $error");
        return;
      }

      completer.completeError(error, stack);
    });

    unawaited(run);

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
      final kind = reportedByTestFramework ? null : benignErrorKind(details.exceptionAsString());

      if (kind != null) {
        debugPrint("Ignoring benign $kind error: ${details.exceptionAsString()}");
        return;
      }

      bindingHandler?.call(details);
    };
  }
}
