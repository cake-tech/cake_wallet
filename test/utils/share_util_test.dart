import "dart:async";

import "package:cake_wallet/utils/share_util.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:share_plus/share_plus.dart";

const _shareChannel = MethodChannel("dev.fluttercommunity.plus/share");

void main() {
  group("ShareUtil", () {
    late GlobalKey pageKey;
    late GlobalKey buttonKey;
    Rect? origin;

    Future<void> pumpPage(WidgetTester tester, {PlatformException? shareError}) async {
      // iPad 6th gen in portrait, the device in the iPadOS 17 field report.
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      origin = null;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(_shareChannel, (call) async {
        final args = call.arguments as Map;
        origin = Rect.fromLTWH(
          args["originX"] as double,
          args["originY"] as double,
          args["originWidth"] as double,
          args["originHeight"] as double,
        );
        if (shareError != null) {
          throw shareError;
        }
        return "";
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(_shareChannel, null),
      );

      pageKey = GlobalKey();
      buttonKey = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            key: pageKey,
            appBar: AppBar(
              actions: [
                IconButton(key: buttonKey, icon: const Icon(Icons.share), onPressed: () {}),
              ],
            ),
            body: const SizedBox.expand(),
          ),
        ),
      );
    }

    // Shares from the page and returns the errors nobody handled: in the app those reach
    // PlatformDispatcher.onError and open the crash-report dialog.
    Future<List<Object>> shareAndCollectUnhandled(WidgetTester tester) async {
      final unhandled = <Object>[];
      runZonedGuarded(
        () => ShareUtil.share(text: "seed", context: pageKey.currentContext!),
        (error, _) => unhandled.add(error),
      );
      await tester.pump();
      return unhandled;
    }

    testWidgets(
      "anchors a page context at the page centre on iOS",
      (tester) async {
        await pumpPage(tester);

        ShareUtil.share(text: "seed", context: pageKey.currentContext!);
        await tester.pump();

        expect(origin, Rect.fromCenter(center: const Offset(384, 512), width: 1, height: 1));
      },
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );

    testWidgets(
      "keeps a button context's own rect on iOS",
      (tester) async {
        await pumpPage(tester);

        ShareUtil.share(text: "seed", context: buttonKey.currentContext!);
        await tester.pump();

        final button = tester.renderObject<RenderBox>(find.byKey(buttonKey));
        expect(origin, button.localToGlobal(Offset.zero) & button.size);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );

    testWidgets(
      "keeps a page context's full rect off iOS",
      (tester) async {
        await pumpPage(tester);

        ShareUtil.share(text: "seed", context: pageKey.currentContext!);
        await tester.pump();

        expect(origin, const Rect.fromLTWH(0, 0, 768, 1024));
      },
      variant: TargetPlatformVariant.only(TargetPlatform.android),
    );

    testWidgets(
      "drops the error for a share requested while another sheet is open",
      (tester) async {
        await pumpPage(
          tester,
          // The error from the iPadOS 17 field report.
          shareError: PlatformException(
            code: "error",
            message: "sharePositionOrigin: argument must be set, {{0, 0}, {768, 1024}} must be "
                "non-zero and within coordinate space of source view: {{0, 0}, {0, 100}}",
          ),
        );

        expect(await shareAndCollectUnhandled(tester), isEmpty);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );

    testWidgets(
      "still lets other share errors through",
      (tester) async {
        await pumpPage(
          tester,
          shareError: PlatformException(code: "error", message: "No root view controller found"),
        );

        final unhandled = await shareAndCollectUnhandled(tester);

        expect(unhandled, hasLength(1));
        expect(
          unhandled.single,
          isA<PlatformException>()
              .having((e) => e.message, "message", "No root view controller found"),
        );
      },
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );

    testWidgets(
      "shareFile drops the error for a share requested while another sheet is open",
      (tester) async {
        await pumpPage(
          tester,
          // The error from the iOS 27 iPhone field report (Export Lightning logs).
          shareError: PlatformException(
            code: "error",
            message: "sharePositionOrigin: argument must be set, {{0, 57}, {390, 787}} must be "
                "non-zero and within coordinate space of source view: {{0, 0}, {372, 369.67}}",
          ),
        );

        final result = await ShareUtil.shareFile(
          filePath: "/logs/lightning.log",
          fileName: "Lightning.log",
          context: pageKey.currentContext!,
        );

        expect(result, ShareResult.unavailable);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );

    testWidgets(
      "shareFile still lets other share errors through",
      (tester) async {
        await pumpPage(
          tester,
          shareError: PlatformException(code: "error", message: "No root view controller found"),
        );

        await expectLater(
          ShareUtil.shareFile(
            filePath: "/logs/lightning.log",
            fileName: "Lightning.log",
            context: pageKey.currentContext!,
          ),
          throwsA(
            isA<PlatformException>()
                .having((e) => e.message, "message", "No root view controller found"),
          ),
        );
      },
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );
  });
}
