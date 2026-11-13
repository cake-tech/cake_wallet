import "package:analyzer/analysis_rule/analysis_rule.dart";
import "package:analyzer/analysis_rule/rule_context.dart";
import "package:analyzer/analysis_rule/rule_visitor_registry.dart";
import "package:analyzer/dart/ast/ast.dart";
import "package:analyzer/dart/ast/visitor.dart";
import "package:analyzer/dart/element/element.dart";
import "package:analyzer/dart/element/type.dart";
import "package:analyzer/error/error.dart";
import "package:cw_custom_lints/utils/test_keys.dart";

class TestKeyInterpolationRule extends AnalysisRule {
  TestKeyInterpolationRule()
    : super(
        name: "no_string_interpolation_in_test_key",
        description:
            "Test keys become accessibility identifiers in release builds, so they must not interpolate strings that can hold user data.",
      );

  static const LintCode code = LintCode(
    "no_string_interpolation_in_test_key",
    "Interpolating a String into a test key would ship user data in release-build accessibility identifiers.",
    correctionMessage: "Use an index, an enum's .name, or a static id instead.",
    severity: DiagnosticSeverity.WARNING,
  );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final filePath = context.definingUnit.file.path;
    if (filePath.contains("/integration_test/")) {
      return;
    }

    registry.addInstanceCreationExpression(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AnalysisRule rule;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final literal = testKeyLiteral(node);
    if (literal is! StringInterpolation) {
      return;
    }

    for (final element in literal.elements.whereType<InterpolationExpression>()) {
      if (_mayHoldUserText(element.expression)) {
        rule.reportAtNode(element);
      }
    }
  }

  bool _mayHoldUserText(Expression expression) {
    if (_isEnumName(expression)) {
      return false;
    }

    final type = expression.staticType;
    return type == null || type is DynamicType || type is InvalidType || type.isDartCoreString;
  }

  bool _isEnumName(Expression expression) {
    final (target, name) = switch (expression) {
      PrefixedIdentifier() => (expression.prefix, expression.identifier.name),
      PropertyAccess() => (expression.target, expression.propertyName.name),
      _ => (null, null),
    };

    return name == "name" && target?.staticType?.element is EnumElement;
  }
}
