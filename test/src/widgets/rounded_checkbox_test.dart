import "package:cake_wallet/src/widgets/rounded_checkbox.dart";
import "package:flutter/material.dart";
import "package:flutter/semantics.dart";
import "package:flutter_test/flutter_test.dart";

final _checkableNodes = find.semantics.byFlag(SemanticsFlag.hasCheckedState);

final _labelledNodes = find.semantics.byPredicate(
  (node) => node.label.isNotEmpty,
  describeMatch: (_) => "labelled SemanticsNodes",
);

Future<void> _pump(WidgetTester tester, Widget child) =>
    tester.pumpWidget(MaterialApp(home: Scaffold(body: Center(child: child))));

void main() {
  group("RoundedCheckbox semantics", () {
    testWidgets("a checked box reports the checked state", (tester) async {
      await _pump(tester, RoundedCheckbox(value: true));

      expect(_checkableNodes, findsOne);
      expect(
        tester.getSemantics(find.byType(RoundedCheckbox)),
        containsSemantics(hasCheckedState: true, isChecked: true),
      );
    });

    testWidgets("the check glyph does not become its own node", (tester) async {
      await _pump(tester, RoundedCheckbox(value: true));

      expect(_labelledNodes, findsNothing);
      expect(_checkableNodes, findsOne);
    });

    testWidgets("the checked state carries no name of its own", (tester) async {
      await _pump(tester, RoundedCheckbox(value: true));

      // Deliberately not a semantics container: the state is meant to merge into
      // the enclosing row/option node instead of adding a second focus stop.
      expect(tester.getSemantics(find.byType(RoundedCheckbox)).label, isEmpty);
    });

    // KNOWN DEFECT, skipped rather than asserted: unchecked renders `Offstage()`,
    // a zero-sized subtree, and Flutter drops zero-rect nodes from the semantics
    // tree -- so the `checked: false` annotation never reaches a screen reader and
    // an unselected option announces nothing at all. Giving the unchecked
    // indicator the same 20x20 footprint as the checked one fixes it, but that
    // shifts layout in the two pickers that use it, so it needs a design call
    // first. Drop the `skip` once the widget is fixed.
    testWidgets(
      "an unchecked box still reports the unchecked state",
      (tester) async {
        await _pump(tester, RoundedCheckbox(value: false));

        expect(_checkableNodes, findsOne);
        expect(
          tester.getSemantics(find.byType(RoundedCheckbox)),
          containsSemantics(hasCheckedState: true, isChecked: false),
        );
      },
      skip: true,
    );
  });
}
