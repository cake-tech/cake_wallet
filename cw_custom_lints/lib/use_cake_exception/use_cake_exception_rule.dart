import "package:analyzer/analysis_rule/analysis_rule.dart";
import "package:analyzer/analysis_rule/rule_context.dart";
import "package:analyzer/analysis_rule/rule_visitor_registry.dart";
import "package:analyzer/dart/ast/ast.dart";
import "package:analyzer/dart/ast/visitor.dart";
import "package:analyzer/error/error.dart";

class UseCakeExceptionRule extends AnalysisRule {
  UseCakeExceptionRule()
    : super(name: "use_cake_exception", description: "please use a CakeException subclass instead");

  static const LintCode code = LintCode(
    "use_cake_exception",
    "please use a CakeException subclass instead",
    severity: DiagnosticSeverity.WARNING,
  );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addThrowExpression(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AnalysisRule rule;

  @override
  void visitThrowExpression(ThrowExpression node) {
    final thrown = node.expression;
    if (thrown is! InstanceCreationExpression) {
      return;
    }

    final type = thrown.constructorName.type;
    if (type.name.lexeme != "Exception") {
      return;
    }

    final library = type.element?.library;
    if (library != null && !library.isDartCore) {
      return;
    }

    rule.reportAtNode(node);
  }
}
