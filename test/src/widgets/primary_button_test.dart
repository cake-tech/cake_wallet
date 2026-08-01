import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/widgets/primary_button.dart";
import "package:flutter/material.dart";
import "package:flutter/semantics.dart";
import "package:flutter_test/flutter_test.dart";

/// The stops a screen reader would actually visit, in traversal order.
List<SemanticsNode> _stops(WidgetTester tester) =>
    tester.semantics.simulatedAccessibilityTraversal().toList();

/// Pass `settle: false` for the loading variants: the Cupertino spinner runs a
/// repeating animation, so [WidgetTester.pumpAndSettle] would never return.
Future<void> _pump(WidgetTester tester, Widget child, {bool settle = true}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [S.delegate],
      supportedLocales: S.delegate.supportedLocales,
      locale: const Locale("en", ""),
      home: Scaffold(body: Center(child: child)),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump();
  }
}

void main() {
  setUpAll(() {
    S.current = const S();
  });

  // PrimaryButton no longer wraps itself in Semantics; the node comes from the
  // TextButton inside it, so these tests pin the base behaviour that replaced it.
  group("PrimaryButton", () {
    testWidgets("reports one enabled button node named after its text", (tester) async {
      await _pump(
        tester,
        PrimaryButton(
          text: "Continue",
          color: Colors.blue,
          textColor: Colors.white,
          onPressed: () {},
        ),
      );

      expect(_stops(tester), hasLength(1));
      expect(
        _stops(tester).single,
        containsSemantics(
          label: "Continue",
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
    });

    testWidgets("a semantic tap invokes onPressed", (tester) async {
      var pressed = 0;
      await _pump(
        tester,
        PrimaryButton(
          text: "Continue",
          color: Colors.blue,
          textColor: Colors.white,
          onPressed: () => pressed++,
        ),
      );

      tester.semantics.tap(find.semantics.byLabel("Continue"));
      await tester.pump();

      expect(pressed, 1);
    });

    testWidgets("reports disabled while keeping the label", (tester) async {
      await _pump(
        tester,
        PrimaryButton(
          text: "Continue",
          color: Colors.blue,
          textColor: Colors.white,
          isDisabled: true,
          onPressed: () {},
        ),
      );

      expect(
        _stops(tester).single,
        containsSemantics(
          label: "Continue",
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
          hasTapAction: false,
        ),
      );
    });

    testWidgets("a missing onPressed also reads as disabled", (tester) async {
      await _pump(
        tester,
        PrimaryButton(text: "Continue", color: Colors.blue, textColor: Colors.white),
      );

      expect(
        _stops(tester).single,
        containsSemantics(label: "Continue", isEnabled: false, hasTapAction: false),
      );
    });

    testWidgets("the dotted-border variant is still a single named node", (tester) async {
      await _pump(
        tester,
        PrimaryButton(
          text: "Continue",
          color: Colors.blue,
          textColor: Colors.white,
          isDottedBorder: true,
          onPressed: () {},
        ),
      );

      expect(_stops(tester), hasLength(1));
      expect(_stops(tester).single, containsSemantics(label: "Continue", isButton: true));
    });

    // Without the old Semantics wrapper there is no longer an `enabled: false`
    // annotation independent of the TextButton's callback, so a button that is
    // visually disabled but wired to onDisabledPressed now reports ENABLED.
    // See the note in the PR description.
    testWidgets("a disabled button with onDisabledPressed reports enabled", (tester) async {
      var explained = 0;
      await _pump(
        tester,
        PrimaryButton(
          text: "Continue",
          color: Colors.blue,
          textColor: Colors.white,
          isDisabled: true,
          onPressed: () {},
          onDisabledPressed: () => explained++,
        ),
      );

      expect(
        _stops(tester).single,
        containsSemantics(label: "Continue", isEnabled: true, hasTapAction: true),
      );

      tester.semantics.tap(find.semantics.byLabel("Continue"));
      await tester.pump();

      expect(explained, 1);
    });
  });

  group("LoadingPrimaryButton", () {
    testWidgets("keeps its label and reports disabled while loading", (tester) async {
      await _pump(
        tester,
        LoadingPrimaryButton(
          text: "Send",
          color: Colors.blue,
          textColor: Colors.white,
          isLoading: true,
          onPressed: () {},
        ),
        settle: false,
      );

      // The spinner has replaced the visible caption...
      expect(find.text("Send"), findsNothing);
      // ...but the accessible name survives, alongside a "loading" value.
      expect(_stops(tester), hasLength(1));
      expect(
        tester.getSemantics(find.byType(LoadingPrimaryButton)),
        containsSemantics(
          label: "Send",
          value: S.current.loading,
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
          hasTapAction: false,
        ),
      );
    });

    testWidgets("a loading button cannot be activated", (tester) async {
      var pressed = 0;
      await _pump(
        tester,
        LoadingPrimaryButton(
          text: "Send",
          color: Colors.blue,
          textColor: Colors.white,
          isLoading: true,
          onPressed: () => pressed++,
        ),
        settle: false,
      );

      await tester.tap(find.byType(LoadingPrimaryButton));
      await tester.pump();

      expect(pressed, 0);
    });

    testWidgets("reports enabled and no value when idle", (tester) async {
      await _pump(
        tester,
        LoadingPrimaryButton(
          text: "Send",
          color: Colors.blue,
          textColor: Colors.white,
          onPressed: () {},
        ),
      );

      expect(
        tester.getSemantics(find.byType(LoadingPrimaryButton)),
        containsSemantics(
          label: "Send",
          value: "",
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
    });

    testWidgets("a semantic tap invokes onPressed when idle", (tester) async {
      var pressed = 0;
      await _pump(
        tester,
        LoadingPrimaryButton(
          text: "Send",
          color: Colors.blue,
          textColor: Colors.white,
          onPressed: () => pressed++,
        ),
      );

      tester.semantics.tap(find.semantics.byLabel("Send"));
      await tester.pump();

      expect(pressed, 1);
    });

    testWidgets("isDisabled reports disabled without a loading value", (tester) async {
      await _pump(
        tester,
        LoadingPrimaryButton(
          text: "Send",
          color: Colors.blue,
          textColor: Colors.white,
          isDisabled: true,
          onPressed: () {},
        ),
      );

      expect(
        tester.getSemantics(find.byType(LoadingPrimaryButton)),
        containsSemantics(label: "Send", value: "", isEnabled: false, hasTapAction: false),
      );
    });
  });
}
