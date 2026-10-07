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
        isSemantics(hasCheckedState: true, isChecked: true),
      );
    });

    testWidgets("the check glyph does not become its own node", (tester) async {
      await _pump(tester, RoundedCheckbox(value: true));

      expect(_labelledNodes, findsNothing);
      expect(_checkableNodes, findsOne);
    });

    testWidgets("the checked state carries no name of its own", (tester) async {
      await _pump(tester, RoundedCheckbox(value: true));

      expect(tester.getSemantics(find.byType(RoundedCheckbox)).label, isEmpty);
    });

    testWidgets(
      "an unchecked box still reports the unchecked state",
      (tester) async {
        await _pump(tester, RoundedCheckbox(value: false));

        expect(_checkableNodes, findsOne);
        expect(
          tester.getSemantics(find.byType(RoundedCheckbox)),
          isSemantics(hasCheckedState: true, isChecked: false),
        );
      },
      skip: true,
    );
  });
}
