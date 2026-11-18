import "package:flutter/semantics.dart";
import "package:flutter_test/flutter_test.dart";

List<SemanticsNode> platformNodesWithId(WidgetTester tester, String identifier) {
  final result = <SemanticsNode>[];

  void visit(SemanticsNode node) {
    if (!node.isMergedIntoParent && node.getSemanticsData().identifier == identifier) {
      result.add(node);
    }
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(tester.binding.renderViews.first.owner!.semanticsOwner!.rootSemanticsNode!);
  return result;
}

List<SemanticsNode> screenReaderStops(WidgetTester tester) =>
    tester.semantics.simulatedAccessibilityTraversal().toList();
