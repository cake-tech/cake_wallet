import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/send_page/send_memo_input.dart";
import "package:flutter/material.dart";
import "package:flutter/semantics.dart";
import "package:flutter_test/flutter_test.dart";

/// The memo field uses the same `MergeSemantics > Semantics(label:) > TextField`
/// wrapper as the amount field. Unlike the amount field it has no `FormField`
/// and no non-container `Semantics` sibling, so nothing can absorb its node —
/// these tests lock that in, because the two were treated together in the
/// CW-1574 audit and only the amount field regressed on device.

SemanticsNode _nodeLabelled(String label) => find.semantics.byLabel(label).evaluate().single;

/// Every semantics node between [node] and the root, nearest first.
List<SemanticsNode> _ancestorsOf(SemanticsNode node) {
  final ancestors = <SemanticsNode>[];
  for (var current = node.parent; current != null; current = current.parent) {
    ancestors.add(current);
  }
  return ancestors;
}

Future<void> _pump(WidgetTester tester, {TextEditingController? memoController}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [S.delegate],
      supportedLocales: S.delegate.supportedLocales,
      locale: const Locale("en", ""),
      home: Scaffold(
        body: NewSendMemoInput(
          memoController: memoController ?? TextEditingController(),
          maxMemoLength: 100,
          memoLength: memoController?.text.length ?? 0,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    S.current = const S();
  });

  group("NewSendMemoInput", () {
    testWidgets("exposes a focusable, editable, named text-field node", (tester) async {
      await _pump(tester);

      expect(find.semantics.byFlag(SemanticsFlag.isTextField), findsOne);

      final field = tester.getSemantics(find.byType(TextField));
      expect(
        field,
        containsSemantics(
          isTextField: true,
          isEnabled: true,
          isFocusable: true,
          hasEnabledState: true,
          hasFocusAction: true,
          hasTapAction: true,
        ),
      );
      expect(field.label, contains(S.current.memo_optional));
    });

    testWidgets("keeps its label once text has been entered", (tester) async {
      await _pump(tester, memoController: TextEditingController(text: "for rent"));

      expect(
        tester.getSemantics(find.byType(TextField)),
        containsSemantics(label: S.current.memo_optional, value: "for rent", isTextField: true),
      );
    });

    testWidgets("is not wrapped in a labelled or actionable container", (tester) async {
      await _pump(tester);

      for (final ancestor in _ancestorsOf(tester.getSemantics(find.byType(TextField)))) {
        final data = ancestor.getSemanticsData();
        expect(
          data.label,
          isEmpty,
          reason: "an ancestor of the memo field carries the label \"${data.label}\"",
        );
        expect(data.hasFlag(SemanticsFlag.isButton), isFalse);
        expect(data.hasAction(SemanticsAction.tap), isFalse);
      }
    });

    testWidgets("reports the character limit on the field instead of as loose text",
        (tester) async {
      await _pump(tester, memoController: TextEditingController(text: "hi"));

      expect(
        tester.getSemantics(find.byType(TextField)),
        containsSemantics(maxValueLength: 100, currentValueLength: 2),
      );
      // The visual "2 / 100" counter must not become its own announcement.
      expect(find.semantics.byLabel("2 / 100"), findsNothing);
    });

    testWidgets("keeps the paste button as a separate named control", (tester) async {
      await _pump(tester);

      expect(find.semantics.byLabel(S.current.paste), findsOne);
      expect(
        _nodeLabelled(S.current.paste),
        containsSemantics(label: S.current.paste, isButton: true, hasTapAction: true),
      );
    });
  });
}
