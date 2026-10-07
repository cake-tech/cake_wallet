import "package:analyzer_testing/analysis_rule/analysis_rule.dart";
import "package:cw_custom_lints/test_key_interpolation/test_key_interpolation_rule.dart";
import "package:test/test.dart";

class _RuleTest extends AnalysisRuleTest {
  @override
  bool get addFlutterPackageDep => true;

  @override
  void setUp() {
    rule = TestKeyInterpolationRule();
    super.setUp();
  }
}

void main() {
  late _RuleTest t;

  setUp(() => t = _RuleTest()..setUp());
  tearDown(() => t.tearDown());

  test("flags an interpolated String", () async {
    const code = r"""
import "package:flutter/foundation.dart";

Key build(String word) => ValueKey("seed_verification_option_${word}_button_key");
""";
    await t.assertDiagnostics(code, [t.lint(code.indexOf(r"${word}"), r"${word}".length)]);
  });

  test("flags a bare String identifier", () async {
    const code = r"""
import "package:flutter/foundation.dart";

Key build(String address) => Key("standard_list_item_$address\_key");
""";
    await t.assertDiagnostics(code, [t.lint(code.indexOf(r"$address"), r"$address".length)]);
  });

  test("flags dynamic", () async {
    const code = r"""
import "package:flutter/foundation.dart";

Key build(dynamic id) => ValueKey("trade_${id}_key");
""";
    await t.assertDiagnostics(code, [t.lint(code.indexOf(r"${id}"), r"${id}".length)]);
  });

  test("allows int", () async {
    await t.assertNoDiagnostics(r"""
import "package:flutter/foundation.dart";

Key build(int index) => ValueKey("home_page_transaction_${index}_key");
""");
  });

  test("allows enums and enum .name", () async {
    await t.assertNoDiagnostics(r"""
import "package:flutter/foundation.dart";

enum Range { day, week }

Key a(Range range) => ValueKey("chart_range_${range}_key");
Key b(Range range) => ValueKey("chart_range_${range.name}_key");
""");
  });

  test("ignores keys that are not test keys", () async {
    await t.assertNoDiagnostics(r"""
import "package:flutter/foundation.dart";

Key build(String name) => ValueKey("contact_$name");
""");
  });

  test("ignores strings that are not keys", () async {
    await t.assertNoDiagnostics(r"""
String build(String name) => "label_${name}_key";
""");
  });
}
