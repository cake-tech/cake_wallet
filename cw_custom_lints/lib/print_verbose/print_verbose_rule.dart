import "package:analyzer/error/error.dart" hide LintCode;
import "package:analyzer/error/listener.dart";
import "package:custom_lint_builder/custom_lint_builder.dart";
import "package:cw_custom_lints/print_verbose/print_verbose_fix.dart";

class PrintVerboseRule extends DartLintRule {
  const PrintVerboseRule() : super(code: _code);

  static const _code = LintCode(
    name: "use_print_v",
    problemMessage: "Use printV() from cw_core instead",
    correctionMessage: "Replace print with printV",
    errorSeverity: ErrorSeverity.WARNING,
  );

  @override
  void run(
      CustomLintResolver resolver,
      ErrorReporter reporter,
      CustomLintContext context,
      ) {
    final filePath = resolver.source.fullName;

    if (filePath.contains("/tool/")) {
      // tool/ is allowed to use print as it never makes its way into the app
      return;
    }

    context.registry.addMethodInvocation((node) {
      if (node.methodName.name == "print" && node.target == null) {
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

  @override
  List<Fix> getFixes() => [ReplaceWithPrintV()];
}
