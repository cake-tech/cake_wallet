import "dart:async";

import "package:cake_wallet/new-ui/widgets/new_future_primary_button.dart";
import "package:cake_wallet/new-ui/widgets/new_primary_button.dart";
import "package:flutter/material.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:flutter_test/flutter_test.dart";

const _svg = '<svg xmlns="http://www.w3.org/2000/svg" width="8" height="8"/>';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  NewPrimaryButton inner(WidgetTester tester) =>
      tester.widget<NewPrimaryButton>(find.byType(NewPrimaryButton));

  Future<void>? fire(WidgetTester tester) {
    final result = (inner(tester).onPressed as dynamic)();
    return result is Future<void> ? result : null;
  }

  Widget build({
    required Future<void> Function() onPressed,
    bool disabled = false,
    SvgPicture? image,
    Color color = Colors.blue,
    Color textColor = Colors.white,
    Color borderColor = Colors.transparent,
    String text = "Send",
  }) =>
      wrap(
        NewFuturePrimaryButton(
          onPressed: onPressed,
          text: text,
          color: color,
          textColor: textColor,
          borderColor: borderColor,
          disabled: disabled,
          image: image,
        ),
      );

  group("NewFuturePrimaryButton", () {
    group("prop forwarding", () {
      testWidgets("passes every prop through to NewPrimaryButton", (tester) async {
        final image = SvgPicture.string(_svg);

        await tester.pumpWidget(
          build(
            onPressed: () async {},
            text: "Confirm",
            color: Colors.green,
            textColor: Colors.black,
            borderColor: Colors.red,
            disabled: true,
            image: image,
          ),
        );

        final button = inner(tester);
        expect(button.text, "Confirm");
        expect(button.color, Colors.green);
        expect(button.textColor, Colors.black);
        expect(button.borderColor, Colors.red);
        expect(button.disabled, isTrue);
        expect(button.image, same(image));
      });

      testWidgets("defaults: transparent border, not disabled, no image", (tester) async {
        await tester.pumpWidget(
          wrap(
            NewFuturePrimaryButton(
              onPressed: () async {},
              text: "Send",
              color: Colors.blue,
              textColor: Colors.white,
            ),
          ),
        );

        final button = inner(tester);
        expect(button.borderColor, Colors.transparent);
        expect(button.disabled, isFalse);
        expect(button.image, isNull);
      });

      testWidgets("starts out not loading", (tester) async {
        await tester.pumpWidget(build(onPressed: () async {}));

        expect(inner(tester).isLoading, isFalse);
      });
    });

    group("loading lifecycle", () {
      testWidgets("flips isLoading true while pending, false once resolved", (tester) async {
        final completer = Completer<void>();
        await tester.pumpWidget(build(onPressed: () => completer.future));

        final pressed = fire(tester);
        await tester.pump();
        expect(
          inner(tester).isLoading,
          isTrue,
          reason: "should be loading while the future is in flight",
        );

        completer.complete();
        await pressed;
        await tester.pump();
        expect(inner(tester).isLoading, isFalse);
      });

      testWidgets("synchronous-ish callback still settles back to not loading", (tester) async {
        var calls = 0;
        await tester.pumpWidget(build(onPressed: () async => calls++));

        await fire(tester);
        await tester.pump();

        expect(calls, 1);
        expect(inner(tester).isLoading, isFalse);
      });

      testWidgets("invokes the callback exactly once per press", (tester) async {
        var calls = 0;
        await tester.pumpWidget(build(onPressed: () async => calls++));

        await fire(tester);
        await tester.pump();
        await fire(tester);
        await tester.pump();

        expect(calls, 2);
      });
    });

    testWidgets("ignores presses while a previous future is pending", (tester) async {
      final completer = Completer<void>();
      var calls = 0;
      await tester.pumpWidget(
        build(
          onPressed: () {
            calls++;
            return completer.future;
          },
        ),
      );

      final pressed = fire(tester);
      await tester.pump();

      unawaited(fire(tester));
      unawaited(fire(tester));
      unawaited(fire(tester));
      await tester.pump();

      expect(calls, 1, reason: "extra presses must be swallowed");

      completer.complete();
      await pressed;
      await tester.pump();

      await fire(tester);
      await tester.pump();
      expect(calls, 2);
    });

    group("handle errors", () {
      testWidgets("clears the loading flag when the callback throws", (tester) async {
        await tester.pumpWidget(
          build(onPressed: () async => throw StateError("boom")),
        );

        await expectLater(fire(tester), throwsA(isA<StateError>()));
        await tester.pump();

        expect(inner(tester).isLoading, isFalse, reason: "the finally block must reset the flag");
      });

      testWidgets("rethrows instead of swallowing the failure", (tester) async {
        await tester.pumpWidget(
          build(onPressed: () async => throw StateError("boom")),
        );

        await expectLater(fire(tester), throwsA(isA<StateError>()));
      });

      testWidgets("stays pressable after the callback throws", (tester) async {
        var calls = 0;
        await tester.pumpWidget(
          build(
            onPressed: () {
              calls++;
              throw StateError("boom");
            },
          ),
        );

        await expectLater(fire(tester), throwsA(isA<StateError>()));
        await tester.pump();
        await expectLater(fire(tester), throwsA(isA<StateError>()));
        await tester.pump();

        expect(calls, 2, reason: "the re-entrancy guard must not latch on failure");
        expect(inner(tester).isLoading, isFalse);
      });
    });

    group("disposal mid-flight", () {
      testWidgets("does not setState after being disposed", (tester) async {
        final completer = Completer<void>();
        await tester.pumpWidget(build(onPressed: () => completer.future));

        final pressed = fire(tester);
        await tester.pump();

        await tester.pumpWidget(wrap(const SizedBox.shrink()));
        expect(find.byType(NewPrimaryButton), findsNothing);

        completer.complete();
        await pressed;
        await tester.pump();

        expect(
          tester.takeException(),
          isNull,
          reason: "the mounted check must guard the second setState",
        );
      });

      testWidgets("still propagates a throw when disposed", (tester) async {
        final completer = Completer<void>();
        await tester.pumpWidget(build(onPressed: () => completer.future));

        final pressed = fire(tester);
        await tester.pump();
        await tester.pumpWidget(wrap(const SizedBox.shrink()));

        completer.completeError(StateError("boom"));

        await expectLater(pressed, throwsA(isA<StateError>()));
        expect(
          tester.takeException(),
          isNull,
          reason: "no setState-after-dispose FlutterError on the error path",
        );
      });
    });

    testWidgets("disabled is forwarded but not enforced by this wrapper", (tester) async {
      // Press-blocking lives in NewPrimaryButton; this widget only relays the
      // flag. If that ever moves up here, this expectation should change.
      var calls = 0;
      await tester.pumpWidget(
        build(onPressed: () async => calls++, disabled: true),
      );

      expect(inner(tester).disabled, isTrue);

      await fire(tester);
      await tester.pump();
      expect(calls, 1);
    });
  });
}
