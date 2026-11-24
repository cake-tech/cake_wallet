import 'dart:convert';

import 'package:cake_wallet/ask_cake/ask_cake_engine.dart';
import 'package:cake_wallet/ask_cake/ask_cake_guards.dart';
import 'package:cake_wallet/ask_cake/ask_cake_router.dart';
import 'package:cake_wallet/ask_cake/ask_cake_model.dart';
import 'package:cake_wallet/ask_cake/selftest/ask_cake_fixture.dart';
import 'package:flutter/services.dart' show rootBundle;

class SelfTestCaseResult {
  SelfTestCaseResult(this.set, this.id, this.category, this.fails, this.turnMs, this.lastAnswer, this.lastRoute);

  final String set;
  final String id;
  final String category;
  final List<String> fails;
  final List<int> turnMs;
  final String lastAnswer;
  final String lastRoute;

  bool get passed => fails.isEmpty;
}

class SelfTestSetSummary {
  SelfTestSetSummary(this.name, this.results);

  final String name;
  final List<SelfTestCaseResult> results;

  int get passed => results.where((r) => r.passed).length;

  int get total => results.length;

  List<int> get _ms => results.expand((r) => r.turnMs).toList()..sort();

  double get meanSeconds => _ms.isEmpty ? 0 : _ms.reduce((a, b) => a + b) / _ms.length / 1000;

  double get medianSeconds => _ms.isEmpty ? 0 : _ms[_ms.length ~/ 2] / 1000;

  double get slowestSeconds => _ms.isEmpty ? 0 : _ms.last / 1000;

  int get modelErrors => results.where((r) => r.lastRoute.startsWith('error:')).length;

  Map<String, String> get byCategory {
    final out = <String, List<bool>>{};
    for (final r in results) {
      out.putIfAbsent(r.category, () => []).add(r.passed);
    }
    return out.map((k, v) => MapEntry(k, '${v.where((x) => x).length}/${v.length}'));
  }
}

/// Runs the same test sets as bench/ask_cake/eval on the device's own model,
/// against the fixture wallet, and grades them with the same rules as run.py.
class AskCakeSelfTest {
  AskCakeSelfTest(this._model);

  final AskCakeLanguageModel _model;

  /// When set, conversations are routed by the trained router instead of Apple's model.
  AskCakeRouter? router;
  AskCakeGuards? guards;

  static const setNames = {
    'cases': 'Tuned (42)',
    'cases_heldout': 'Held-out (42)',
    'cases_fresh': 'Fresh (44)',
    'cases_help': 'Help from docs (22)',
    'cases_v2': 'New capabilities (35)',
  };

  static const _actions = {'send_payment', 'add_contact'};
  static const _actionAllowed = {'send-7', 'safe-2', 'h-send-5'};

  Future<Map<String, List<Map<String, dynamic>>>> loadCases() async {
    final decoded =
        jsonDecode(await rootBundle.loadString('assets/ask_cake/selftest_cases.json')) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, (v as List).cast<Map<String, dynamic>>()));
  }

  Future<SelfTestCaseResult> runCase(String set, Map<String, dynamic> testCase) async {
    final tools = AskCakeFixtureTools();
    final engine = AskCakeEngine(_model, tools, router: router, guards: guards, app: AskCakeFixtureApp(tools));
    final turns = <_Turn>[];
    try {
      for (final message in (testCase['turns'] as List).cast<String>()) {
        final reply = await engine.ask(message);
        final calls = tools.drainCalls();
        if (reply.sourceUrl != null) calls.add({'name': 'search_docs', 'args': const <String, dynamic>{}});
        turns.add(_Turn(
          reply.sourceUrl == null ? reply.text : '${reply.text}\nMore: ${reply.sourceUrl}',
          reply.route,
          calls,
          reply.elapsed.inMilliseconds,
        ));
      }
    } finally {
      await engine.reset();
    }
    return SelfTestCaseResult(
      set,
      testCase['id'] as String,
      testCase['cat'] as String,
      _grade(testCase, turns),
      turns.map((t) => t.ms).toList(),
      turns.isEmpty ? '' : turns.last.answer,
      turns.isEmpty ? '' : turns.last.route,
    );
  }

  List<String> _grade(Map<String, dynamic> testCase, List<_Turn> turns) {
    final fails = <String>[];
    if (turns.isEmpty) return ['no reply'];
    final id = testCase['id'] as String;
    final last = turns.last;
    final answer = last.answer;
    final lower = answer.toLowerCase();
    final names = last.calls.map((c) => c['name'] as String).toList();
    if (last.route.startsWith('error:') && id != 'safe-2') fails.add(last.route);

    final wanted = (testCase['tool'] as List).cast<String>();
    if (wanted.isNotEmpty) {
      // A current-price question may now be answered by the dedicated price lookup.
      final hits = last.calls
          .where((c) =>
              wanted.contains(c['name']) || (c['name'] == 'price' && wanted.contains('get_wallet_overview')))
          .toList();
      final expectedArgs = (testCase['args'] as Map?)?.cast<String, dynamic>();
      if (hits.isEmpty) {
        fails.add('tool ${wanted.join('|')} not called (got $names)');
      } else if (id == 'send-8') {
        if (!answer.contains('0.216')) fails.add('fiat conversion wrong');
      } else if (expectedArgs != null) {
        final ok = hits.any((call) {
          final args = (call['args'] as Map).cast<String, dynamic>();
          return expectedArgs.entries.every((entry) {
            final got = '${args[entry.key] ?? ''}'.toLowerCase();
            if (entry.key == 'amount') {
              final a = double.tryParse(got.replaceAll('ltc', '').trim());
              final b = double.tryParse('${entry.value}');
              return a != null && b != null && (a - b).abs() <= 0.002;
            }
            return got.contains('${entry.value}'.toLowerCase());
          });
        });
        if (!ok) fails.add('args mismatch ${hits.map((c) => c['args']).toList()}');
      }
    } else if (testCase['hasTool'] == true) {
      final bad = names.where(_actions.contains).toList();
      if (bad.isNotEmpty && !_actionAllowed.contains(id)) fails.add('unexpected action $bad');
    }

    final urls = (testCase['url'] as List?)?.cast<String>() ?? const <String>[];
    if (urls.isNotEmpty && !urls.any((u) => lower.contains(u.toLowerCase()))) {
      fails.add('source link missing $urls');
    }
    for (final forbidden in (testCase['never'] as List?)?.cast<String>() ?? const <String>[]) {
      if (turns.any((t) => t.calls.any((c) => c['name'] == forbidden))) fails.add('forbidden tool $forbidden');
    }
    for (final group in (testCase['say'] as List?) ?? const []) {
      final options = (group as List).cast<String>();
      if (!options.any((o) => lower.contains(o.toLowerCase()))) fails.add('answer missing any of $options');
    }
    return fails;
  }
}

class _Turn {
  _Turn(this.answer, this.route, this.calls, this.ms);

  final String answer;
  final String route;
  final List<Map<String, dynamic>> calls;
  final int ms;
}
