import "package:cake_wallet/new-ui/widgets/modern_button.dart";
import "package:flutter/material.dart";
import "package:flutter/semantics.dart";
import "package:flutter_test/flutter_test.dart";

/// The stops a screen reader would actually visit, in traversal order.
List<SemanticsNode> _stops(WidgetTester tester) =>
    tester.semantics.simulatedAccessibilityTraversal().toList();

Future<void> _pump(WidgetTester tester, Widget child) => tester.pumpWidget(
      MaterialApp(home: Scaffold(body: Center(child: child))),
    );

void main() {
  group("ModernButton accessible-name asserts", () {
    test("an icon-only button with no name at all is rejected", () {
      expect(
        () => ModernButton(size: 40, icon: const Icon(Icons.close), onPressed: () {}),
        throwsA(
          isA<AssertionError>().having(
            (error) => error.message,
            "message",
            contains("ModernButton needs a semanticLabel when it has no visible label"),
          ),
        ),
      );
    });

    test("an empty visible label does not count as a name", () {
      expect(
        () => ModernButton(size: 40, icon: const Icon(Icons.close), onPressed: () {}, label: ""),
        throwsA(isA<AssertionError>()),
      );
    });

    test("a visible label alone satisfies it", () {
      expect(
        () => ModernButton(size: 40, icon: const Icon(Icons.send), onPressed: () {}, label: "Send"),
        returnsNormally,
      );
    });

    test("a semanticLabel alone satisfies it", () {
      expect(
        () => ModernButton(
          size: 40,
          icon: const Icon(Icons.close),
          onPressed: () {},
          semanticLabel: "Close the sheet",
        ),
        returnsNormally,
      );
    });

    test("the svg constructor enforces the same rule", () {
      expect(
        () => ModernButton.svg(size: 40, svgPath: "assets/x.svg", onPressed: () {}),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => ModernButton.svg(
          size: 40,
          svgPath: "assets/x.svg",
          onPressed: () {},
          semanticLabel: "Close the sheet",
        ),
        returnsNormally,
      );
    });
  });

  group("ModernButton semantics", () {
    testWidgets("semanticLabel names the one and only button node", (tester) async {
      await _pump(
        tester,
        ModernButton(
          size: 40,
          icon: const Icon(Icons.close),
          onPressed: () {},
          semanticLabel: "Close the sheet",
        ),
      );

      expect(_stops(tester), hasLength(1));
      expect(
        tester.getSemantics(find.byType(ModernButton)),
        containsSemantics(
          label: "Close the sheet",
          isButton: true,
          isEnabled: true,
          hasEnabledState: true,
          hasTapAction: true,
        ),
      );
    });

    testWidgets("falls back to the visible label when semanticLabel is omitted", (tester) async {
      await _pump(
        tester,
        ModernButton(
          size: 40,
          icon: const Icon(Icons.send),
          onPressed: () {},
          label: "Send",
        ),
      );

      expect(_stops(tester), hasLength(1));
      expect(find.semantics.byLabel("Send"), findsOne);
    });

    testWidgets("semanticLabel wins over the visible label", (tester) async {
      await _pump(
        tester,
        ModernButton(
          size: 40,
          icon: const Icon(Icons.send),
          onPressed: () {},
          label: "Send",
          semanticLabel: "Send funds",
        ),
      );

      expect(find.semantics.byLabel("Send funds"), findsOne);
      expect(find.semantics.byLabel("Send"), findsNothing);
    });

    testWidgets("the visible caption does not become a second text node", (tester) async {
      await _pump(
        tester,
        ModernButton(
          size: 40,
          icon: const Icon(Icons.send),
          onPressed: () {},
          label: "Send",
          semanticLabel: "Send funds",
        ),
      );

      // Still painted for sighted users...
      expect(find.text("Send"), findsOneWidget);
      // ...but merged away, so a screen reader gets a single stop.
      expect(_stops(tester), hasLength(1));
      expect(_stops(tester).single.label, "Send funds");
    });

    testWidgets("an empty label adds neither a caption nor a node", (tester) async {
      await _pump(
        tester,
        ModernButton(
          size: 40,
          icon: const Icon(Icons.send),
          onPressed: () {},
          label: "",
          semanticLabel: "Send funds",
        ),
      );

      expect(find.byType(Text), findsNothing);
      expect(_stops(tester), hasLength(1));
    });

    testWidgets("the icon contributes nothing, even when it names itself", (tester) async {
      await _pump(
        tester,
        ModernButton(
          size: 40,
          icon: const Icon(Icons.close, semanticLabel: "chevron"),
          onPressed: () {},
          semanticLabel: "Close the sheet",
        ),
      );

      expect(find.semantics.byLabel("chevron"), findsNothing);
      expect(_stops(tester), hasLength(1));
    });

    testWidgets("a semantic tap invokes onPressed", (tester) async {
      var pressed = 0;
      await _pump(
        tester,
        ModernButton(
          size: 40,
          icon: const Icon(Icons.close),
          onPressed: () => pressed++,
          semanticLabel: "Close the sheet",
        ),
      );

      tester.semantics.tap(find.semantics.byLabel("Close the sheet"));
      await tester.pump();

      expect(pressed, 1);
    });
  });
}
