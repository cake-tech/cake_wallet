import "package:flutter/semantics.dart";
import "package:flutter_test/flutter_test.dart";

List<SemanticsNode> platformNodesWithId(WidgetTester tester, String identifier) {
  final result = <SemanticsNode>[];

  void visit(SemanticsNode node) {
    if (!node.isMergedIntoParent && node.identifier == identifier) {
      result.add(node);
    }
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!);
  return result;
}
