import "package:analyzer/analysis_rule/analysis_rule.dart";
import "package:analyzer/analysis_rule/rule_context.dart";
import "package:analyzer/analysis_rule/rule_visitor_registry.dart";
import "package:analyzer/dart/ast/ast.dart";
import "package:analyzer/dart/ast/visitor.dart";
import "package:analyzer/error/error.dart";
import "package:cw_custom_lints/utils/test_keys.dart";
import "package:cw_custom_lints/utils/widget_arguments.dart";

class TestKeySemanticsRule extends AnalysisRule {
  TestKeySemanticsRule()
    : super(
        name: "require_test_key_semantics_identifier",
        description:
            "A test key on a framework interactive widget needs a matching Semantics identifier so UI drivers can find it.",
      );

  static const LintCode code = LintCode(
    "require_test_key_semantics_identifier",
    "This test key is invisible to accessibility-tree drivers without a Semantics identifier.",
    correctionMessage: "Wrap the widget in TestId.merge with the same id.",
    severity: DiagnosticSeverity.WARNING,
  );

  static const interactiveWidgets = {
    "GestureDetector",
    "InkWell",
    "TextButton",
    "IconButton",
    "ElevatedButton",
    "OutlinedButton",
    "FilledButton",
    "TextField",
    "TextFormField",
    "Switch",
    "Checkbox",
    "Radio",
    "ListTile",
    "CupertinoButton",
  };

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) =>
      registry.addInstanceCreationExpression(this, _Visitor(this));
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AnalysisRule rule;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (!isFlutterClass(node.constructorName, TestKeySemanticsRule.interactiveWidgets)) {
      return;
    }

    if (testKeyLiteral(namedArgumentExpression(node.argumentList, "key")) == null) {
      return;
    }

    if (_hasIdentifierAncestor(node)) {
      return;
    }

    rule.reportAtNode(node.constructorName);
  }

  bool _hasIdentifierAncestor(AstNode node) {
    for (AstNode? current = node.parent; current != null; current = current.parent) {
      if (current is MethodDeclaration ||
          current is FunctionDeclaration ||
          current is ClassDeclaration ||
          current is CompilationUnit) {
        return false;
      }

      if (current is InstanceCreationExpression &&
          current.constructorName.type.name.lexeme == "Semantics" &&
          namedArgument(current.argumentList, "identifier") != null) {
        return true;
      }

      if (current is MethodInvocation &&
          current.target is SimpleIdentifier &&
          (current.target! as SimpleIdentifier).name == "TestId" &&
          const {"merge", "container"}.contains(current.methodName.name)) {
        return true;
      }
    }

    return false;
  }
}
