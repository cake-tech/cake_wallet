import "package:analyzer/error/error.dart" hide LintCode;
import "package:analyzer/error/listener.dart";
import "package:custom_lint_builder/custom_lint_builder.dart";

class RestrictedImportsRule extends DartLintRule {
  const RestrictedImportsRule() : super(code: _code);

  static const _code = LintCode(
    name: "no_restricted_imports_in_lib",
    problemMessage:
        "Do not import from coin-specific packages. If necessary, wire your logic through configure.dart",
    errorSeverity: ErrorSeverity.ERROR,
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
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final filePath = resolver.source.fullName;
    final fileName = filePath.split("/").last;

    // ignore cw_something folders
    if (filePath.contains("cw_")) {
      return;
    }

    // allow ex. cw_bitcoin in bitcoin.dart
    if(_restrictedPackages.contains("cw_"+fileName.replaceAll(".dart", ""))) {
      return;
    }

    context.registry.addImportDirective((node) {
      final uriString = node.uri.stringValue;
      if (uriString == null || !uriString.startsWith("package:")) {
        return;
      }

      final pathWithoutScheme = uriString.replaceFirst("package:", "");
      final packageName = pathWithoutScheme.split("/").first;

      if (_restrictedPackages.contains(packageName)) {
        reporter.reportError(
          AnalysisError.forValues(
            source: resolver.source,
            offset: node.offset,
            length: node.length,
            errorCode: _code,
            message: _code.problemMessage,
          ),
        );
      }
    });
  }
}
