import "package:analysis_server_plugin/edit/dart/correction_producer.dart";
import "package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart";
import "package:analyzer/dart/ast/ast.dart";
import "package:analyzer_plugin/utilities/change_builder/change_builder_core.dart";
import "package:analyzer_plugin/utilities/fixes/fixes.dart";
import "package:analyzer_plugin/utilities/range_factory.dart";

class ReplaceWithPrintV extends ResolvedCorrectionProducer {
  ReplaceWithPrintV({required super.context});

  static const _importString = "package:cw_core/utils/print_verbose.dart";

  static const _fixKind = FixKind(
    "dart.fix.replaceWithPrintV",
    DartFixKindPriority.standard,
    "Replace with printV()",
  );

  @override
  CorrectionApplicability get applicability => CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final invocation = node.thisOrAncestorOfType<MethodInvocation>();
    if (invocation == null) {
      return;
    }

    final root = invocation.root;
    final hasImport = root is CompilationUnit &&
        root.directives.whereType<ImportDirective>().any(
              (directive) => directive.uri.stringValue == _importString,
            );

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(
        range.node(invocation.methodName),
        "printV",
      );

      if (!hasImport) {
        builder.importLibrary(Uri.parse(_importString));
      }
    });
  }
}
