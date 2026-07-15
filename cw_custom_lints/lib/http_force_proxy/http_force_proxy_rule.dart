import "package:analyzer/analysis_rule/analysis_rule.dart";
import "package:analyzer/analysis_rule/rule_context.dart";
import "package:analyzer/analysis_rule/rule_visitor_registry.dart";
import "package:analyzer/dart/ast/ast.dart";
import "package:analyzer/dart/ast/visitor.dart";
import "package:analyzer/error/error.dart";

class HttpForceProxyRule extends AnalysisRule {
  HttpForceProxyRule()
      : super(
          name: "no_http_imports",
          description:
              "Using the http package breaks proxy integration. Please use ProxyWrapper or alias it as \"very_insecure_http_do_not_use\".",
        );

  static const LintCode code = LintCode(
    "no_http_imports",
    "Using the http package breaks proxy integration. Please use ProxyWrapper or alias it as \"very_insecure_http_do_not_use\".",
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

    if (filePath.endsWith("proxy_wrapper.dart")) {
      return;
    }

    registry.addImportDirective(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AnalysisRule rule;

  @override
  void visitImportDirective(ImportDirective node) {
    final uriString = node.uri.stringValue;
    if (uriString == null) {
      return;
    }

    if (uriString.startsWith("package:http")) {
      final prefixNode = node.prefix;
      if (prefixNode != null && prefixNode.name == "very_insecure_http_do_not_use") {
        return;
      }

      rule.reportAtNode(node);
    }
  }
}
