import 'package:cake_wallet/ask_cake/ask_cake_guards.dart';
import 'package:cake_wallet/ask_cake/ask_cake_model.dart';
import 'package:cake_wallet/ask_cake/ask_cake_page.dart';
import 'package:cake_wallet/ask_cake/ask_cake_router.dart';
import 'package:cake_wallet/ask_cake/ask_cake_router_store.dart';
import 'package:cake_wallet/ask_cake/ask_cake_usage_log.dart';
import 'package:cake_wallet/utils/share_util.dart';
import 'package:cake_wallet/ask_cake/selftest/ask_cake_selftest.dart';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Hidden page (long-press the "Ask Cake" title) that measures how well this
/// device's on-device model handles the Ask Cake test sets. It uses a fixture
/// wallet only; the real wallet is never read.
class AskCakeSelfTestPage extends StatefulWidget {
  const AskCakeSelfTestPage({super.key});

  @override
  State<AskCakeSelfTestPage> createState() => _AskCakeSelfTestPageState();
}

class _AskCakeSelfTestPageState extends State<AskCakeSelfTestPage> {
  final _model = AppleFoundationLanguageModel();
  late final _selfTest = AskCakeSelfTest(_model);
  final _summaries = <SelfTestSetSummary>[];
  AskCakeAvailability? _availability;
  bool _running = false;
  bool _cancel = false;
  String _progress = '';
  final _router = CoreMlAskCakeRouter();
  bool _routerReady = false;
  bool _useRouter = false;
  String _routerNote = 'Trained router: loading';
  int _logLines = 0;

  @override
  void initState() {
    super.initState();
    _model.availability().then((value) {
      if (mounted) setState(() => _availability = value);
    });
    _loadRouter();
  }

  Future<void> _loadRouter() async {
    final guards = await AskCakeGuards.load();
    final problem = await _router.prepare(path: await AskCakeRouterStore().locate());
    _logLines = await AskCakeUsageLog.lineCount();
    if (!mounted) return;
    setState(() {
      _selfTest.guards = guards;
      _routerReady = problem == null;
      _useRouter = _routerReady;
      _routerNote = problem == null
          ? 'Trained router: ready, loaded in ${_router.lastLoadMs} ms'
          : 'Trained router: not available ($problem)';
    });
  }

  @override
  void dispose() {
    _router.release();
    _cancel = true;
    WakelockPlus.disable();
    super.dispose();
  }

  Future<void> _run(List<String> sets) async {
    setState(() {
      _running = true;
      _cancel = false;
      _summaries.clear();
    });
    await WakelockPlus.enable();
    _selfTest.router = _useRouter ? _router : null;
    try {
      final cases = await _selfTest.loadCases();
      for (final set in sets) {
        final results = <SelfTestCaseResult>[];
        final list = cases[set] ?? const [];
        for (var i = 0; i < list.length; i++) {
          if (_cancel || !mounted) return;
          setState(() => _progress =
              '${AskCakeSelfTest.setNames[set]}: ${i + 1}/${list.length} (${results.where((r) => r.passed).length} passed)');
          results.add(await _selfTest.runCase(set, list[i]));
        }
        if (!mounted) return;
        setState(() => _summaries.add(SelfTestSetSummary(set, results)));
      }
    } finally {
      await WakelockPlus.disable();
      if (mounted) {
        setState(() {
          _running = false;
          _progress = _cancel ? 'Stopped' : 'Done';
        });
        if (kDebugMode) {
          for (final line in _report().split('\n')) {
            debugPrint('ASKCAKE SELFTEST $line');
          }
        }
      }
    }
  }

  String _report() {
    final a = _availability;
    final lines = <String>[
      'Ask Cake self-test | model: ${a?.modelName ?? '?'} | context: ${a?.contextSize ?? '?'}',
      _useRouter ? 'routing: trained SmolLM2-135M | ${_router.stats}' : 'routing: Apple model',
    ];
    for (final s in _summaries) {
      lines.add('${s.name}: ${s.passed}/${s.total} | mean ${s.meanSeconds.toStringAsFixed(1)}s '
          'median ${s.medianSeconds.toStringAsFixed(1)}s slowest ${s.slowestSeconds.toStringAsFixed(1)}s '
          '| model errors ${s.modelErrors} | ${s.byCategory}');
      for (final r in s.results.where((r) => !r.passed)) {
        final answer = r.lastAnswer.replaceAll('\n', ' / ');
        lines.add('  FAIL ${r.id} [${r.lastRoute}] ${r.fails.join('; ')} -> '
            '${answer.length > 160 ? answer.substring(0, 160) : answer}');
      }
    }
    return lines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final a = _availability;
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        title: const Text('Ask Cake self-test', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              a == null
                  ? 'Checking model…'
                  : a.available
                      ? 'Model: ${a.modelName} · context ${a.contextSize} tokens'
                      : a.reasonText,
              key: const ValueKey('ask_cake_selftest_model'),
              style: TextStyle(fontSize: 14, color: colors.onSurface),
            ),
            const SizedBox(height: 6),
            Text(
              'Runs 150 scripted conversations against a built-in fictional wallet. Your real wallet is not read. '
              'Keep this screen open; it takes several minutes.',
              style: TextStyle(fontSize: 13, height: 1.35, color: colors.onSurfaceVariant),
            ),
            SwitchListTile(
              key: const ValueKey('ask_cake_selftest_use_router'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Route with the trained router'),
              subtitle: Text(_routerNote),
              value: _useRouter,
              onChanged: _running || !_routerReady ? null : (value) => setState(() => _useRouter = value),
            ),
            SwitchListTile(
              key: const ValueKey('ask_cake_selftest_show_details'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Show routing details in the chat'),
              subtitle: const Text('Adds a line under each reply: capability chosen, timing, how sure the router was.'),
              value: AskCakePage.showRoutingDetails.value,
              onChanged: (value) => setState(() => AskCakePage.showRoutingDetails.value = value),
            ),
            SwitchListTile(
              key: const ValueKey('ask_cake_selftest_test_log'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Keep a test log on this phone'),
              subtitle: Text('Saves what you ask, how it was routed and which buttons you press, to a file on this '
                  'phone. Addresses are removed and nothing is sent anywhere; you share the file yourself. '
                  '$_logLines lines so far.'),
              value: AskCakeUsageLog.enabled.value,
              onChanged: (value) async {
                await AskCakeUsageLog.setEnabled(value);
                if (mounted) setState(() {});
              },
            ),
            if (_logLines > 0)
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    key: const ValueKey('ask_cake_selftest_share_log'),
                    onPressed: () async {
                      final log = await AskCakeUsageLog.file();
                      if (context.mounted) {
                        await ShareUtil.shareFile(filePath: log.path, fileName: 'ask_cake_test_log.jsonl', context: context);
                      }
                    },
                    icon: const Icon(Icons.ios_share, size: 18),
                    label: const Text('Share log'),
                  ),
                  TextButton(
                    key: const ValueKey('ask_cake_selftest_delete_log'),
                    onPressed: () async {
                      await AskCakeUsageLog.clear();
                      if (mounted) setState(() => _logLines = 0);
                    },
                    child: const Text('Delete log'),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  key: const ValueKey('ask_cake_selftest_run_all'),
                  onPressed: _running || a?.available != true
                      ? null
                      : () => _run(AskCakeSelfTest.setNames.keys.toList()),
                  child: const Text('Run all'),
                ),
                OutlinedButton(
                  key: const ValueKey('ask_cake_selftest_run_quick'),
                  onPressed:
                      _running || a?.available != true ? null : () => _run(const ['cases_fresh', 'cases_help']),
                  child: const Text('Quick (fresh + help)'),
                ),
                if (_running)
                  TextButton(onPressed: () => setState(() => _cancel = true), child: const Text('Stop')),
                if (!_running && _summaries.isNotEmpty)
                  OutlinedButton.icon(
                    key: const ValueKey('ask_cake_selftest_copy'),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: _report()));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(content: Text('Results copied')));
                      }
                    },
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copy results'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_progress.isNotEmpty)
              Text(_progress,
                  key: const ValueKey('ask_cake_selftest_progress'),
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.onSurface)),
            const SizedBox(height: 8),
            for (final s in _summaries) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration:
                    BoxDecoration(color: colors.surfaceContainer, borderRadius: BorderRadius.circular(14)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${AskCakeSelfTest.setNames[s.name]}: ${s.passed}/${s.total} passed',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colors.onSurface)),
                    const SizedBox(height: 4),
                    Text(
                      'Per reply: mean ${s.meanSeconds.toStringAsFixed(1)} s, median ${s.medianSeconds.toStringAsFixed(1)} s, '
                      'slowest ${s.slowestSeconds.toStringAsFixed(1)} s · model errors ${s.modelErrors}',
                      style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
                    ),
                    Text(s.byCategory.entries.map((e) => '${e.key} ${e.value}').join(' · '),
                        style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant)),
                    for (final r in s.results.where((r) => !r.passed))
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text('${r.id}: ${r.fails.join('; ')}',
                            style: TextStyle(fontSize: 11, color: colors.error)),
                      ),
                  ],
                ),
              ),
            ],
            if (_summaries.isNotEmpty && !_running)
              SelectableText(_report(), style: TextStyle(fontSize: 10, color: colors.onSurfaceVariant)),
            const Divider(height: 32),
            const _RouterBenchPanel(),
          ],
        ),
      ),
    );
  }
}

/// Developer-only: runs the router models copied into Documents/askcake_bench and writes result files there.
class _RouterBenchPanel extends StatefulWidget {
  const _RouterBenchPanel();

  @override
  State<_RouterBenchPanel> createState() => _RouterBenchPanelState();
}

class _RouterBenchPanelState extends State<_RouterBenchPanel> {
  static const _channel = MethodChannel('com.cake_wallet/ask_cake');
  Timer? _timer;
  bool _running = false;
  String _status = '';
  List<String> _lines = const [];

  @override
  void initState() {
    super.initState();
    _poll();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _poll() async {
    try {
      final snapshot = await _channel.invokeMapMethod<String, dynamic>('benchStatus') ?? {};
      if (!mounted) return;
      setState(() {
        _running = snapshot['running'] == true;
        _status = snapshot['status'] as String? ?? '';
        _lines = (snapshot['lines'] as List?)?.cast<String>() ?? const [];
      });
      _timer?.cancel();
      if (_running) {
        _timer = Timer(const Duration(seconds: 2), _poll);
      } else {
        WakelockPlus.disable();
      }
    } on MissingPluginException {
      // Not on iOS: the panel stays idle.
    }
  }

  Future<void> _start() async {
    await WakelockPlus.enable();
    await _channel.invokeMethod<bool>('benchStart');
    await _poll();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Router bench', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.onSurface)),
        const SizedBox(height: 6),
        Text(
          'Runs the router models and jobs copied into this app\'s Documents/askcake_bench folder. '
          'Keep this screen open until it says done.',
          style: TextStyle(fontSize: 13, height: 1.35, color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        FilledButton(
          key: const ValueKey('ask_cake_router_bench_run'),
          onPressed: _running ? null : _start,
          child: Text(_running ? 'Running…' : 'Run router bench'),
        ),
        const SizedBox(height: 8),
        if (_status.isNotEmpty)
          Text(_status,
              key: const ValueKey('ask_cake_router_bench_status'),
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.onSurface)),
        for (final line in _lines)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(line, style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant)),
          ),
      ],
    );
  }
}
