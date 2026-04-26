import "package:analyzer/dart/ast/ast.dart";
import "package:analyzer/error/error.dart" hide LintCode;
import "package:custom_lint_builder/custom_lint_builder.dart";

class ReplaceWithPrintV extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    AnalysisError error,
    List<AnalysisError> others,
  ) {
    context.registry.addMethodInvocation((node) {
      const importString = "package:cw_core/utils/print_verbose.dart";

      if (!error.sourceRange.intersects(node.sourceRange)) {
        return;
      }

      final root = node.root;
      final hasImport = root is CompilationUnit &&
          root.directives.whereType<ImportDirective>().any(
                (directive) => directive.uri.stringValue == importString,
              );

      final changeBuilder = reporter.createChangeBuilder(
        message: "Replace with printV()",
        priority: 999999,
      );

      changeBuilder.addDartFileEdit((builder) {
        builder.addSimpleReplacement(node.methodName.sourceRange, "printV");

        if (!hasImport) {
          builder.importLibrary(Uri.parse(importString));
        }
      });
    });
  }
}
