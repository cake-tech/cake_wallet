import "package:analyzer/error/error.dart" hide LintCode;
import "package:analyzer/error/listener.dart";
import "package:custom_lint_builder/custom_lint_builder.dart";

class HttpForceProxyRule extends DartLintRule {
  const HttpForceProxyRule() : super(code: _code);

  static const _code = LintCode(
    name: "no_http_imports",
    problemMessage:
        "Using the http package breaks proxy integration. Please use ProxyWrapper or alias it as \"very_insecure_http_do_not_use\".",
    errorSeverity: ErrorSeverity.WARNING,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final filePath = resolver.source.fullName;

    if (filePath.endsWith("proxy_wrapper.dart")) {
      return;
    }

    context.registry.addImportDirective((node) {
      final uriString = node.uri.stringValue;
      if (uriString == null) {
        return;
      }

      if (uriString.startsWith("package:http")) {
        final prefixNode = node.prefix;
        if (prefixNode != null && prefixNode.name == "very_insecure_http_do_not_use") {
          return;
        }

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
