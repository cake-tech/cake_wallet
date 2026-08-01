import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/send_page/send_amount_input.dart";
import "package:flutter/material.dart";
import "package:flutter/semantics.dart";
import "package:flutter_test/flutter_test.dart";

/// Two on-device findings shaped this file (CW-1574).
///
/// D1: the amount field produced no node in the Android accessibility tree at
/// all. `FormField` wraps its builder output in its own non-container
/// `Semantics(validationResult: ...)` annotation, and that annotation becomes
/// the node parenting everything the field renders. The currency picker's
/// `Semantics` had no `container: true`, so it was not a boundary either and
/// its configuration was absorbed into that same wrapper — turning the whole
/// field into one labelled, tappable container with the text field hidden
/// underneath. Pinned below by the ancestor walk.
///
/// D1 follow-on: with the node back, the device announced the amount twice —
/// once on `FormField`'s wrapper node, once on the field itself. The framework
/// tree never showed that: it held exactly one node carrying the label and
/// that node *was* the text field, with `isImage` false everywhere. The
/// wrapper's Flutter label is empty, so the text and the ImageView role the
/// device showed on it are synthesized platform-side from its descendants.
/// `FormField`'s wrapper cannot be removed, so the field now carries no label
/// of its own and the visible "Amount:" caption stays in the semantics tree to
/// name it. Pinned below by the single-Amount-stop tests.
///
/// What only the device audit can see: whether the platform bridge collapses,
/// splits or re-describes these nodes. These tests can only pin the framework
/// tree the bridge is handed — one field node, named by an adjacent caption,
/// with no label authored anywhere that a container could reflect. A change
/// here that keeps these tests green still needs a device re-check.

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

/// Mirrors the send page: the caption is a plain, announced `Text` and the
/// field that follows carries no label of its own.
///
/// Only ever one amount section here. The send page renders one per recipient,
/// so the "exactly one" assertions below are per-section properties — a
/// multi-recipient screen legitimately has one caption and one field each,
/// which is why the device gate counts them with a minimum rather than an
/// exact count.
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
            Text(S.current.amount),
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

    testWidgets("exposes the typed amount as its value", (tester) async {
      await _pump(tester, amountController: TextEditingController(text: "1.23"));

      expect(
        tester.getSemantics(find.byType(TextField)),
        containsSemantics(value: "1.23", isTextField: true),
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
    });
  });

  group("NewSendAmountInput naming", () {
    testWidgets("the caption names the field and is the only Amount stop", (tester) async {
      await _pump(tester);

      final stops = _stops(tester);
      final amountStops = stops.where((node) => node.label.contains(S.current.amount)).toList();

      expect(
        amountStops,
        hasLength(1),
        reason: "the amount must be announced once. Labels found: "
            "${stops.map((node) => node.label).toList()}",
      );
      expect(
        amountStops.single.getSemanticsData().hasFlag(SemanticsFlag.isTextField),
        isFalse,
        reason: "the caption, not the field, carries the name",
      );
    });

    testWidgets("stays a single Amount stop once a value is typed", (tester) async {
      await _pump(tester, amountController: TextEditingController(text: "1.23"));

      expect(
        _stops(tester).where((node) => node.label.contains(S.current.amount)),
        hasLength(1),
      );
    });

    testWidgets("the caption is the stop immediately before the field", (tester) async {
      await _pump(tester);

      final stops = _stops(tester);
      final captionIndex = stops.indexWhere((node) => node.label.contains(S.current.amount));
      final fieldIndex =
          stops.indexWhere((node) => node.getSemanticsData().hasFlag(SemanticsFlag.isTextField));

      expect(captionIndex, isNonNegative);
      expect(
        fieldIndex,
        captionIndex + 1,
        reason: "the field is named by adjacency, so nothing may come between the "
            "caption and the field. Order: ${stops.map((node) => node.label).toList()}",
      );
    });

    testWidgets("the field carries no label of its own to be reflected", (tester) async {
      await _pump(tester, amountController: TextEditingController(text: "1.23"));

      expect(tester.getSemantics(find.byType(TextField)).label, isEmpty);
    });

    testWidgets("nothing announcing the amount claims the image role", (tester) async {
      await _pump(tester, hasPicker: true);

      expect(find.semantics.byFlag(SemanticsFlag.isImage), findsNothing);
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
