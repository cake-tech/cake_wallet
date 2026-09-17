import "package:analyzer/analysis_rule/analysis_rule.dart";
import "package:analyzer/analysis_rule/rule_context.dart";
import "package:analyzer/analysis_rule/rule_visitor_registry.dart";
import "package:analyzer/dart/ast/ast.dart";
import "package:analyzer/dart/ast/visitor.dart";
import "package:analyzer/error/error.dart";

class NoBareCatchRule extends AnalysisRule {
  NoBareCatchRule()
    : super(
        name: "no_bare_catch",
        description: "please specify the exception class to catch (on SomeException catch (e))",
      );

  static const LintCode code = LintCode(
    "no_bare_catch",
    "please specify the exception class to catch (on SomeException catch (e))",
    severity: DiagnosticSeverity.WARNING,
  );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addCatchClause(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AnalysisRule rule;

  @override
  void visitCatchClause(CatchClause node) {
    if (node.exceptionType != null) {
      return;
    }

    final tryStatement = node.parent;
    if (tryStatement is TryStatement) {
      final precedingClauses = tryStatement.catchClauses.takeWhile((clause) => clause != node);
      if (precedingClauses.any((clause) => clause.exceptionType != null)) {
        return;
      }
    }

    rule.reportAtNode(node);
  }
}
