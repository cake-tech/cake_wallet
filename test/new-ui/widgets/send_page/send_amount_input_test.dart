import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/send_page/send_amount_input.dart";
import "package:flutter/material.dart";
import "package:flutter/semantics.dart";
import "package:flutter_test/flutter_test.dart";

/// An on-device audit found the amount field missing from the Android
/// accessibility tree entirely (CW-1574 / D1). The cause was structural, not
/// visual: `FormField` wraps its builder output in a non-container
/// `Semantics(validationResult: ...)` annotation, and that annotation becomes
/// the node parenting everything the field renders. Any *other* non-container
/// `Semantics` inside the same subtree — here the currency picker — has its
/// configuration absorbed into that same node, turning the whole field into
/// one labelled, tappable container with the text field hidden underneath.
///
/// These tests pin the shape a screen reader needs: the field is its own
/// text-field node, it is named, and nothing labelled or actionable is
/// wrapped around it.

/// The stops a screen reader would actually visit, in traversal order.
List<SemanticsNode> _stops(WidgetTester tester) =>
    tester.semantics.simulatedAccessibilityTraversal().toList();

SemanticsNode _nodeLabelled(String label) => find.semantics.byLabel(label).evaluate().single;

/// Every semantics node between [node] and the root, nearest first.
List<SemanticsNode> _ancestorsOf(SemanticsNode node) {
  final ancestors = <SemanticsNode>[];
  for (var current = node.parent; current != null; current = current.parent) {
    ancestors.add(current);
  }
  return ancestors;
}

Future<void> _pump(
  WidgetTester tester, {
  TextEditingController? amountController,
  bool hasPicker = false,
  FormFieldValidator<String>? validator,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [S.delegate],
      supportedLocales: S.delegate.supportedLocales,
      locale: const Locale("en", ""),
      home: Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            // Mirrors the send page: the caption is excluded because the field
            // is expected to carry the label itself.
            ExcludeSemantics(child: Text(S.current.amount)),
            NewSendAmountInput(
              currency: "BTC",
              currencyIconPath: "",
              hasPicker: hasPicker,
              maxDecimals: 8,
              onPickerClicked: () {},
              amountController: amountController ?? TextEditingController(),
              validator: validator,
            ),
          ],
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

  group("NewSendAmountInput amount field", () {
    testWidgets("is exposed as a focusable, editable text-field node", (tester) async {
      await _pump(tester);

      expect(find.semantics.byFlag(SemanticsFlag.isTextField), findsOne);
      expect(
        tester.getSemantics(find.byType(TextField)),
        containsSemantics(
          isTextField: true,
          isEnabled: true,
          isFocusable: true,
          hasEnabledState: true,
          hasFocusAction: true,
          hasTapAction: true,
        ),
      );
    });

    testWidgets("carries the Amount label even though the caption is excluded", (tester) async {
      await _pump(tester);

      expect(tester.getSemantics(find.byType(TextField)).label, contains(S.current.amount));
    });

    testWidgets("keeps the Amount label and exposes the typed value", (tester) async {
      await _pump(tester, amountController: TextEditingController(text: "1.23"));

      expect(
        tester.getSemantics(find.byType(TextField)),
        containsSemantics(label: S.current.amount, value: "1.23", isTextField: true),
      );
    });

    for (final hasPicker in [false, true]) {
      testWidgets(
        "is not wrapped in a labelled or actionable container (hasPicker: $hasPicker)",
        (tester) async {
          await _pump(tester, hasPicker: hasPicker);

          final field = tester.getSemantics(find.byType(TextField));

          for (final ancestor in _ancestorsOf(field)) {
            final data = ancestor.getSemanticsData();
            expect(
              data.label,
              isEmpty,
              reason: "an ancestor of the amount field carries the label "
                  "\"${data.label}\", so screen readers announce the container "
                  "instead of the field",
            );
            expect(
              data.hasFlag(SemanticsFlag.isButton),
              isFalse,
              reason: "the amount field must not be nested inside a button node",
            );
            expect(
              data.hasAction(SemanticsAction.tap),
              isFalse,
              reason: "the amount field must not be nested inside a tappable container",
            );
          }
        },
      );
    }

    testWidgets("stays a stop of its own in the traversal order", (tester) async {
      await _pump(tester, hasPicker: true);

      final fieldStops = _stops(tester)
          .where((node) => node.getSemanticsData().hasFlag(SemanticsFlag.isTextField));

      expect(fieldStops, hasLength(1));
      expect(fieldStops.single.label, contains(S.current.amount));
    });
  });

  group("NewSendAmountInput currency picker", () {
    testWidgets("is a button node of its own, separate from the field", (tester) async {
      await _pump(tester, hasPicker: true);

      expect(find.semantics.byLabel(S.current.select_asset), findsOne);

      final picker = _nodeLabelled(S.current.select_asset);
      expect(
        picker,
        containsSemantics(
          label: S.current.select_asset,
          value: "BTC",
          isButton: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      expect(
        picker.getSemanticsData().hasFlag(SemanticsFlag.isTextField),
        isFalse,
        reason: "the picker node must not have swallowed the amount text field",
      );
    });

    testWidgets("without a picker the currency is announced but is not a control", (tester) async {
      await _pump(tester);

      expect(find.semantics.byLabel("BTC"), findsOne);

      final currency = _nodeLabelled("BTC").getSemanticsData();
      expect(currency.hasFlag(SemanticsFlag.isButton), isFalse);
      expect(currency.hasAction(SemanticsAction.tap), isFalse);
    });
  });

  group("NewSendAmountInput validation error", () {
    testWidgets("is announced as a live region naming the field", (tester) async {
      await _pump(tester, validator: (_) => " is required");

      tester.state<FormFieldState<String>>(find.byType(FormField<String>)).validate();
      await tester.pumpAndSettle();

      final error = "${S.current.amount} is required";
      expect(find.semantics.byLabel(error), findsOne);
      expect(
        _nodeLabelled(error).getSemanticsData().hasFlag(SemanticsFlag.isLiveRegion),
        isTrue,
      );
    });
  });
}
