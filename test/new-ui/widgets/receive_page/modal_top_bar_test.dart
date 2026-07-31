import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/modern_button.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:flutter/material.dart";
import "package:flutter/semantics.dart";
import "package:flutter_test/flutter_test.dart";

/// The stops a screen reader would actually visit, in traversal order.
List<SemanticsNode> _stops(WidgetTester tester) =>
    tester.semantics.simulatedAccessibilityTraversal().toList();

Set<String> _labels(WidgetTester tester) =>
    _stops(tester).map((node) => node.label).where((label) => label.isNotEmpty).toSet();

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [S.delegate],
      supportedLocales: S.delegate.supportedLocales,
      locale: const Locale("en", ""),
      home: Scaffold(body: child),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    S.current = const S();
  });

  group("ModalTopBar leading button", () {
    testWidgets("announces the localized \"Close\" by default", (tester) async {
      await _pump(
        tester,
        ModalTopBar(title: "Receive", leadingIcon: const Icon(Icons.close)),
      );

      expect(find.semantics.byLabel(S.current.close), findsOne);
    });

    testWidgets("announces a caller-supplied leadingSemanticLabel", (tester) async {
      await _pump(
        tester,
        ModalTopBar(
          title: "Receive",
          leadingIcon: const Icon(Icons.arrow_back),
          leadingSemanticLabel: "Back to wallet",
        ),
      );

      expect(find.semantics.byLabel("Back to wallet"), findsOne);
      expect(find.semantics.byLabel(S.current.close), findsNothing);
    });

    testWidgets("a semantic tap runs onLeadingPressed", (tester) async {
      var pressed = 0;
      await _pump(
        tester,
        ModalTopBar(
          title: "Receive",
          leadingIcon: const Icon(Icons.close),
          onLeadingPressed: () => pressed++,
        ),
      );

      tester.semantics.tap(find.semantics.byLabel(S.current.close));
      await tester.pump();

      expect(pressed, 1);
    });
  });

  group("ModalTopBar trailing button", () {
    testWidgets("announces trailingSemanticLabel", (tester) async {
      await _pump(
        tester,
        ModalTopBar(
          title: "Receive",
          leadingIcon: const Icon(Icons.close),
          trailingIcon: const Icon(Icons.share),
          trailingSemanticLabel: "Share address",
        ),
      );

      expect(find.semantics.byLabel("Share address"), findsOne);
      expect(
        tester.getSemantics(find.byWidgetPredicate(
          (widget) => widget is ModernButton && widget.semanticLabel == "Share address",
        )),
        containsSemantics(label: "Share address", isButton: true, hasTapAction: true),
      );
    });

    testWidgets("contributes no node at all when trailingIcon is null", (tester) async {
      await _pump(
        tester,
        ModalTopBar(title: "Receive", leadingIcon: const Icon(Icons.close)),
      );

      expect(find.byType(ModernButton), findsOneWidget);
      // Only the close button and the title header remain.
      expect(_labels(tester), {S.current.close, "Receive"});
    });
  });

  group("ModalTopBar title", () {
    testWidgets("a non-empty title is exposed as a header", (tester) async {
      await _pump(tester, ModalTopBar(title: "Receive"));

      expect(
        tester.getSemantics(find.text("Receive")),
        containsSemantics(label: "Receive", isHeader: true),
      );
    });

    testWidgets("an empty title is not a header", (tester) async {
      await _pump(tester, ModalTopBar(title: ""));

      expect(find.semantics.byFlag(SemanticsFlag.isHeader), findsNothing);
    });
  });
}
