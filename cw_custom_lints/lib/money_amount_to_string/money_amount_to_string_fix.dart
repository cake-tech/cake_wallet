import "package:analysis_server_plugin/edit/dart/correction_producer.dart";
import "package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart";
import "package:analyzer/dart/ast/ast.dart";
import "package:analyzer_plugin/utilities/change_builder/change_builder_core.dart";
import "package:analyzer_plugin/utilities/fixes/fixes.dart";
import "package:analyzer_plugin/utilities/range_factory.dart";
import "package:cw_custom_lints/money_amount_to_string/money_amount_to_string_rule.dart";

abstract class _ReplaceMoneyAmountToString extends ResolvedCorrectionProducer {
  _ReplaceMoneyAmountToString({required super.context});

  String get replacement;

  @override
  CorrectionApplicability get applicability => CorrectionApplicability.singleLocation;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final invocation = node.thisOrAncestorOfType<MethodInvocation>();
    if (invocation == null) {
      return;
    }

    final amount = moneyAmountReference(invocation.realTarget);
    if (amount == null) {
      return;
    }

    await builder.addDartFileEdit(
      file,
      (builder) => builder.addSimpleReplacement(range.startEnd(amount, invocation), replacement),
    );
  }
}

class ReplaceWithMoneyToString extends _ReplaceMoneyAmountToString {
  ReplaceWithMoneyToString({required super.context});

  static const _fixKind = FixKind(
    "dart.fix.replaceWithMoneyToString",
    DartFixKindPriority.standard,
    "Replace with toString() for a decimal amount",
  );

  @override
  FixKind get fixKind => _fixKind;

  @override
  String get replacement => "toString()";
}

class ReplaceWithMoneyToStringInBaseUnit extends _ReplaceMoneyAmountToString {
  ReplaceWithMoneyToStringInBaseUnit({required super.context});

  static const _fixKind = FixKind(
    "dart.fix.replaceWithMoneyToStringInBaseUnit",
    DartFixKindPriority.standard,
    "Replace with toStringWithPrecision(useBaseUnit: true) for base units",
  );

  @override
  FixKind get fixKind => _fixKind;

  @override
  String get replacement => "toStringWithPrecision(useBaseUnit: true)";
}
