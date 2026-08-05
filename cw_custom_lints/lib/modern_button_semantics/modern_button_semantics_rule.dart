import "package:analyzer/analysis_rule/analysis_rule.dart";
import "package:analyzer/analysis_rule/rule_context.dart";
import "package:analyzer/analysis_rule/rule_visitor_registry.dart";
import "package:analyzer/dart/ast/ast.dart";
import "package:analyzer/dart/ast/visitor.dart";
import "package:analyzer/error/error.dart";
import "package:cw_custom_lints/utils/widget_arguments.dart";

class ModernButtonSemanticsRule extends AnalysisRule {
  ModernButtonSemanticsRule()
    : super(
        name: "require_modern_button_semantics",
        description:
            "ModernButton needs a semanticLabel when it has no visible label, otherwise screen readers announce an unnamed button.",
      );

  static const LintCode code = LintCode(
    "require_modern_button_semantics",
    "ModernButton has no visible label, so screen readers have nothing to announce.",
    correctionMessage: "Pass a localized semanticLabel, or a non-empty label.",
    severity: DiagnosticSeverity.WARNING,
  );

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
    final constructorName = node.constructorName;
    if (!isCakeWalletWidget(constructorName, "ModernButton")) {
      return;
    }

    final argumentList = node.argumentList;
    final hasLabel = !isMissingOrEmptyText(namedArgumentExpression(argumentList, "label"));
    final hasSemanticLabel = !isMissingOrEmptyText(
      namedArgumentExpression(argumentList, "semanticLabel"),
    );

    if (hasLabel || hasSemanticLabel) {
      return;
    }

    rule.reportAtNode(constructorName);
  }
}
