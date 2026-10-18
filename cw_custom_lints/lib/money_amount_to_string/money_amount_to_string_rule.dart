import "package:analyzer/analysis_rule/analysis_rule.dart";
import "package:analyzer/analysis_rule/rule_context.dart";
import "package:analyzer/analysis_rule/rule_visitor_registry.dart";
import "package:analyzer/dart/ast/ast.dart";
import "package:analyzer/dart/ast/visitor.dart";
import "package:analyzer/dart/element/element.dart";
import "package:analyzer/error/error.dart";

class MoneyAmountToStringRule extends AnalysisRule {
  MoneyAmountToStringRule()
      : super(
          name: "no_money_amount_to_string",
          description:
              "Money.amount is the internal BigInt, so stringifying it drops the decimal point.",
        );

  static const LintCode code = LintCode(
    "no_money_amount_to_string",
    "This stringifies the internal BigInt of Money instead of the Money itself, so the decimal point is dropped and the amount reads far larger than it is.",
    correctionMessage:
        "Call toString() on the Money for a decimal amount, or toStringWithPrecision(useBaseUnit: true) for base units.",
    severity: DiagnosticSeverity.WARNING,
  );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) =>
      registry.addMethodInvocation(this, _Visitor(this));
}


SimpleIdentifier? moneyAmountReference(Expression? expression) {
  final identifier = switch (expression) {
    PrefixedIdentifier() => expression.identifier,
    PropertyAccess() => expression.propertyName,
    SimpleIdentifier() => expression,
    _ => null,
  };

  if (identifier == null || identifier.name != "amount") {
    return null;
  }

  return _isDeclaredByMoney(identifier.element) ? identifier : null;
}

bool _isDeclaredByMoney(Element? element) {
  if (element == null) {
    return false;
  }

  final enclosing = element.enclosingElement;
  if (enclosing is! InterfaceElement || enclosing.name != "Money") {
    return false;
  }

  final libraryUri = element.library?.uri;
  if (libraryUri == null || libraryUri.scheme != "package") {
    return false;
  }

  final segments = libraryUri.pathSegments;
  return segments.isNotEmpty && segments.first == "cw_core";
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AnalysisRule rule;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != "toString" || node.argumentList.arguments.isNotEmpty) {
      return;
    }

    if (moneyAmountReference(node.realTarget) == null) {
      return;
    }

    rule.reportAtNode(node);
  }
}
