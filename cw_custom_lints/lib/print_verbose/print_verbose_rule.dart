import "package:analyzer/analysis_rule/analysis_rule.dart";
import "package:analyzer/analysis_rule/rule_context.dart";
import "package:analyzer/analysis_rule/rule_visitor_registry.dart";
import "package:analyzer/dart/ast/ast.dart";
import "package:analyzer/dart/ast/visitor.dart";
import "package:analyzer/error/error.dart";

class PrintVerboseRule extends AnalysisRule {
  PrintVerboseRule()
      : super(
          name: "use_print_v",
          description: "Use printV() from cw_core instead of print().",
        );

  static const LintCode code = LintCode(
    "use_print_v",
    "Use printV() from cw_core instead",
    correctionMessage: "Replace print with printV",
    severity: DiagnosticSeverity.WARNING,
  );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final filePath = context.definingUnit.file.path;

    if (filePath.contains("/tool/") || filePath.contains("print_verbose.dart")) {
      // tool/ is allowed to use print as it never makes its way into the app
      return;
    }

    registry.addMethodInvocation(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AnalysisRule rule;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == "print" && node.target == null) {
      rule.reportAtNode(node);
    }
  }
}
