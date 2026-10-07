import "package:cake_wallet/new-ui/widgets/confirm_swiper.dart";
import "package:cake_wallet/new-ui/widgets/new_primary_button.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

import "../../utils/semantics_helpers.dart";

const _swiperText = "Swipe to send";
const _buttonText = "Confirm and send";

Future<void> _pump(
  WidgetTester tester, {
  required bool accessibleNavigation,
  String? accessibleNavigationModeButtonText,
  VoidCallback? onConfirmed,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(accessibleNavigation: accessibleNavigation),
          child: Scaffold(
            body: Center(
              child: ConfirmSwiper(
                onConfirmed: onConfirmed ?? () {},
                swiperText: _swiperText,
                accessibleNavigationModeButtonText: accessibleNavigationModeButtonText,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group("accessibleNavigation: true", () {
    testWidgets("renders a plain button instead of the swiper", (tester) async {
      await _pump(
        tester,
        accessibleNavigation: true,
        accessibleNavigationModeButtonText: _buttonText,
      );

      expect(find.byType(NewPrimaryButton), findsOneWidget);
      expect(find.byType(FlowingText), findsNothing);
    });

    testWidgets("the button is labelled with accessibleNavigationModeButtonText", (tester) async {
      await _pump(
        tester,
        accessibleNavigation: true,
        accessibleNavigationModeButtonText: _buttonText,
      );

      expect(find.semantics.byLabel(_buttonText), findsOne);
      expect(find.semantics.byLabel(_swiperText), findsNothing);
      expect(
        screenReaderStops(tester).single,
        isSemantics(label: _buttonText, isButton: true, hasTapAction: true, isEnabled: true),
      );
    });

    testWidgets("falls back to swiperText when no button text is supplied", (tester) async {
      await _pump(tester, accessibleNavigation: true);

      expect(find.semantics.byLabel(_swiperText), findsOne);
      expect(
        screenReaderStops(tester).single,
        isSemantics(label: _swiperText, isButton: true, hasTapAction: true),
      );
    });

    testWidgets("a semantic tap on the button confirms", (tester) async {
      var confirmed = 0;
      await _pump(
        tester,
        accessibleNavigation: true,
        accessibleNavigationModeButtonText: _buttonText,
        onConfirmed: () => confirmed++,
      );

      tester.semantics.tap(find.semantics.byLabel(_buttonText));
      await tester.pump();

      expect(confirmed, 1);
    });
  });

  group("accessibleNavigation: false", () {
    testWidgets("exposes exactly one node, labelled with swiperText", (tester) async {
      await _pump(tester, accessibleNavigation: false);

      expect(find.byType(NewPrimaryButton), findsNothing);
      expect(screenReaderStops(tester), hasLength(1));
      expect(screenReaderStops(tester).single.label, _swiperText);
    });

    testWidgets("the decorative label and knob are not separate stops", (tester) async {
      await _pump(tester, accessibleNavigation: false);

      expect(find.byType(FlowingText), findsOneWidget);
      expect(find.semantics.byPredicate((node) => node.label == _swiperText), findsOne);
    });

    testWidgets("offers no tap action, so a tap cannot confirm", (tester) async {
      var confirmed = 0;
      await _pump(tester, accessibleNavigation: false, onConfirmed: () => confirmed++);

      expect(
        screenReaderStops(tester).single,
        isSemantics(label: _swiperText, hasTapAction: false, isButton: false),
      );

      await tester.tap(find.byType(ConfirmSwiper));
      await tester.pump();

      expect(confirmed, 0);
    });

    testWidgets("a horizontal drag across the control still confirms", (tester) async {
      var confirmed = 0;
      await _pump(tester, accessibleNavigation: false, onConfirmed: () => confirmed++);

      final pill = tester.getTopLeft(find.byType(ConfirmSwiper)) + const Offset(28, 26);
      await tester.dragFrom(pill, const Offset(760, 0));
      await tester.pump();

      expect(confirmed, 1);
    });

    testWidgets("a short drag does not confirm", (tester) async {
      var confirmed = 0;
      await _pump(tester, accessibleNavigation: false, onConfirmed: () => confirmed++);

      final pill = tester.getTopLeft(find.byType(ConfirmSwiper)) + const Offset(28, 26);
      await tester.dragFrom(pill, const Offset(120, 0));
      await tester.pump();

      expect(confirmed, 0);
    });
  });
}
