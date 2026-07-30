import "dart:async";

import "package:cake_wallet/main.dart" as app;
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

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
    _filterKnownRenderNoise();

    await app.main(topLevelKey: ValueKey(testKey));

    await tester.pump(const Duration(seconds: 2));
  }

  void _filterKnownRenderNoise() {
    final defaultHandler = FlutterError.onError;

    FlutterError.onError = (details) {
      final message = details.exceptionAsString();

      // Missing .vec assets are reported before CakeImageWidget falls back to parsing the svg
      // at runtime, the app ignores them by design so the tests have to as well.
      final isVecAssetNoise =
          message.contains("Unable to load asset") && message.contains(".svg.vec");

      // Overflow and image loading errors are emulator noise, everything else must fail the test.
      if (isVecAssetNoise ||
          message.contains("overflowed by") ||
          message.contains("NetworkImageLoadException")) {
        debugPrint("Ignoring render noise: $message");
        return;
      }

      defaultHandler?.call(details);
    };
  }
}
