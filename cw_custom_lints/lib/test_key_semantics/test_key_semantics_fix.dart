import "package:analysis_server_plugin/edit/dart/correction_producer.dart";
import "package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart";
import "package:analyzer/dart/ast/ast.dart";
import "package:analyzer_plugin/utilities/change_builder/change_builder_core.dart";
import "package:analyzer_plugin/utilities/fixes/fixes.dart";
import "package:cw_custom_lints/utils/test_keys.dart";
import "package:cw_custom_lints/utils/widget_arguments.dart";

class WrapInTestIdMerge extends ResolvedCorrectionProducer {
  WrapInTestIdMerge({required super.context});

  static const _importString = "package:cake_wallet/utils/test_id.dart";

  static const _fixKind = FixKind(
    "dart.fix.wrapInTestIdMerge",
    DartFixKindPriority.standard,
    "Wrap in TestId.merge()",
  );

  @override
  CorrectionApplicability get applicability => CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final widget = node.thisOrAncestorOfType<InstanceCreationExpression>();
    final literal = widget == null
        ? null
        : testKeyLiteral(namedArgumentExpression(widget.argumentList, "key"));
    if (widget == null || literal == null) {
      return;
    }

    final root = widget.root;
    final hasImport =
        root is CompilationUnit &&
        root.directives.whereType<ImportDirective>().any(
          (directive) => directive.uri.stringValue == _importString,
        );

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleInsertion(widget.offset, "TestId.merge(${literal.toSource()}, child: ");
      builder.addSimpleInsertion(widget.end, ")");

      if (!hasImport) {
        builder.importLibrary(Uri.parse(_importString));
      }
    });
  }
}
