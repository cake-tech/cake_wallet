import "package:analyzer/analysis_rule/analysis_rule.dart";
import "package:analyzer/analysis_rule/rule_context.dart";
import "package:analyzer/analysis_rule/rule_visitor_registry.dart";
import "package:analyzer/dart/ast/ast.dart";
import "package:analyzer/dart/ast/visitor.dart";
import "package:analyzer/error/error.dart";

class RestrictedImportsRule extends AnalysisRule {
  RestrictedImportsRule()
      : super(
          name: "no_restricted_imports_in_lib",
          description:
              "Do not import from coin-specific packages. If necessary, wire your logic through configure.dart",
        );

  static const LintCode code = LintCode(
    "no_restricted_imports_in_lib",
    "Do not import from coin-specific packages. If necessary, wire your logic through configure.dart",
    severity: DiagnosticSeverity.ERROR,
  );

  static const _restrictedPackages = {
    "cw_bitcoin",
    "cw_bitcoin_cash",
    "cw_electrum",
    "cw_litecoin",
    "cw_evm",
    "cw_mweb",
    "cw_nano",
    "cw_solana",
    "cw_tron",
    "cw_zano",
  };

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final filePath = context.definingUnit.file.path;
    final fileName = filePath.split("/").last;

    // ignore cw_something folders
    if (filePath.contains("cw_")) {
      return;
    }

    // allow ex. cw_bitcoin in bitcoin.dart
    if (_restrictedPackages.contains("cw_" + fileName.replaceAll(".dart", ""))) {
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
    if (uriString == null || !uriString.startsWith("package:")) {
      return;
    }

    final pathWithoutScheme = uriString.replaceFirst("package:", "");
    final packageName = pathWithoutScheme.split("/").first;

    if (RestrictedImportsRule._restrictedPackages.contains(packageName)) {
      rule.reportAtNode(node);
    }
  }
}
