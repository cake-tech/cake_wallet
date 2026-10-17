import "package:analyzer_testing/analysis_rule/analysis_rule.dart";
import "package:cw_custom_lints/test_key_semantics/test_key_semantics_rule.dart";
import "package:test/test.dart";

const _fixtures = r"""
import "package:flutter/material.dart";

class Semantics extends StatelessWidget {
  const Semantics({super.key, this.identifier, this.child});
  final String? identifier;
  final Widget? child;
}

abstract final class TestId {
  static Widget merge(String? id, {required Widget child}) => child;
  static Widget container(String? id, {required Widget child}) => child;
}

class CakeButton extends StatelessWidget {
  const CakeButton({super.key});
}
""";

class _RuleTest extends AnalysisRuleTest {
  @override
  bool get addFlutterPackageDep => true;

  @override
  void setUp() {
    rule = TestKeySemanticsRule();
    super.setUp();
  }
}

void main() {
  late _RuleTest t;

  setUp(() => t = _RuleTest()..setUp());
  tearDown(() => t.tearDown());

  Future<void> expectLintAt(String code, String widget) =>
      t.assertDiagnostics(code, [t.lint(code.indexOf("$widget(key"), widget.length)]);

  test("flags a bare GestureDetector", () async {
    await expectLintAt("""
$_fixtures
Widget build() => GestureDetector(key: const ValueKey("send_button_key"));
""", "GestureDetector");
  });

  test("flags an interpolated test key", () async {
    await expectLintAt("""
$_fixtures
Widget build(int i) => InkWell(key: ValueKey("row_\${i}_key"));
""", "InkWell");
  });

  test("flags a Semantics ancestor without identifier", () async {
    await expectLintAt("""
$_fixtures
Widget build() => Semantics(child: GestureDetector(key: const ValueKey("send_button_key")));
""", "GestureDetector");
  });

  test("allows TestId.merge", () async {
    await t.assertNoDiagnostics("""
$_fixtures
Widget build() =>
    TestId.merge("send_button_key", child: GestureDetector(key: const ValueKey("send_button_key")));
""");
  });

  test("allows Semantics(identifier:) across a builder closure", () async {
    await t.assertNoDiagnostics("""
$_fixtures
Widget build() => Semantics(
      identifier: "send_button_key",
      child: Builder(builder: (_) => GestureDetector(key: const ValueKey("send_button_key"))),
    );
""");
  });

  test("ignores identity keys", () async {
    await t.assertNoDiagnostics("""
$_fixtures
Widget build(String name) => GestureDetector(key: ValueKey(name));
""");
  });

  test("ignores strings that are not test keys", () async {
    await t.assertNoDiagnostics("""
$_fixtures
Widget build() => GestureDetector(key: const ValueKey("send"));
""");
  });

  test("ignores Cake widgets", () async {
    await t.assertNoDiagnostics("""
$_fixtures
Widget build() => CakeButton(key: const ValueKey("send_button_key"));
""");
  });

  test("ignores non-interactive framework widgets", () async {
    await t.assertNoDiagnostics("""
$_fixtures
Widget build() => Text("x", key: const ValueKey("title_key"));
""");
  });
}
