import "package:analyzer/analysis_rule/analysis_rule.dart";
import "package:analyzer/analysis_rule/rule_context.dart";
import "package:analyzer/analysis_rule/rule_visitor_registry.dart";
import "package:analyzer/dart/ast/ast.dart";
import "package:analyzer/dart/ast/visitor.dart";
import "package:analyzer/error/error.dart";
import "package:cw_custom_lints/utils/widget_arguments.dart";

class ModalTopBarSemanticsRule extends AnalysisRule {
  ModalTopBarSemanticsRule()
    : super(
        name: "require_modal_top_bar_semantics",
        description:
            "ModalTopBar icons need a semantic label, because the icon alone does not say whether it closes the modal, goes back or does something else.",
      );

  static const LintCode code = LintCode(
    "require_modal_top_bar_semantics",
    "ModalTopBar was given a {0} without a {1}, so screen readers have nothing to announce.",
    correctionMessage: "Pass a localized {1} next to the {0}.",
    severity: DiagnosticSeverity.WARNING,
  );

  static const _iconSemanticLabels = {
    "leadingIcon": "leadingSemanticLabel",
    "trailingIcon": "trailingSemanticLabel",
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
    if (!isCakeWalletWidget(node.constructorName, "ModalTopBar")) {
      return;
    }

    for (final slot in ModalTopBarSemanticsRule._iconSemanticLabels.entries) {
      _checkSlot(node.argumentList, iconName: slot.key, semanticLabelName: slot.value);
    }
  }

  void _checkSlot(
    ArgumentList argumentList, {
    required String iconName,
    required String semanticLabelName,
  }) {
    final icon = namedArgument(argumentList, iconName);
    if (icon == null || icon.argumentExpression is NullLiteral) {
      return;
    }

    if (!isMissingOrEmptyText(namedArgumentExpression(argumentList, semanticLabelName))) {
      return;
    }

    rule.reportAtToken(icon.name, arguments: [iconName, semanticLabelName]);
  }
}
