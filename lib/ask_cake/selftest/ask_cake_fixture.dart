import 'package:cake_wallet/ask_cake/ask_cake_app.dart';
import 'package:cake_wallet/ask_cake/ask_cake_guards.dart';
import 'package:cake_wallet/ask_cake/ask_cake_tools.dart';

/// A fixed, fictional Litecoin wallet used by the on-device self-test so the
/// same questions have the same right answers on every device. Mirrors
/// bench/ask_cake/eval/tools.py; nothing here touches a real wallet.
class AskCakeFixtureTools implements AskCakeToolbox {
  static final _today = DateTime(2026, 11, 18);
  static const _price = 92.40;
  static const _balance = 3.48215;
  static const _address = 'ltc1q8c6fshw2dlwun7ekn9qwf37cu2rn755u9ym7p0';

  // (date, incoming, amount, fee, note)
  static const _txs = [
    ('2026-11-16', false, 0.25, 0.00012, 'Coffee beans order'),
    ('2026-11-14', true, 1.10, 0.0, 'Swap from XMR'),
    ('2026-11-09', false, 0.08, 0.00011, 'VPN renewal'),
    ('2026-11-03', false, 0.50, 0.00014, 'Sent to Alice'),
    ('2026-10-28', true, 0.75, 0.0, 'Freelance invoice 114'),
    ('2026-10-21', false, 0.12, 0.00010, 'Cake Pay gift card'),
    ('2026-10-15', false, 0.30, 0.00013, 'Sent to Bob'),
    ('2026-10-07', true, 2.00, 0.0, 'Freelance invoice 113'),
    ('2026-10-02', false, 1.40, 0.00015, 'Swap to BTC'),
    ('2026-09-24', false, 0.06, 0.00010, 'Domain renewal'),
    ('2026-09-18', true, 0.40, 0.0, 'Refund'),
    ('2026-09-05', false, 0.22, 0.00012, 'Sent to Alice'),
    ('2026-08-30', true, 1.50, 0.0, 'Freelance invoice 112'),
    ('2026-08-11', false, 0.90, 0.00014, 'Swap to XMR'),
    ('2026-07-19', true, 0.65, 0.0, 'Gift from Carol'),
    ('2026-06-02', false, 0.15, 0.00010, 'Hosting'),
  ];
  // (date, provider, from, fromAmount, to, toAmount, state)
  static const _swaps = [
    ('2026-11-14', 'Trocador', 'XMR', 0.62, 'LTC', 1.10, 'complete'),
    ('2026-10-02', 'ChangeNOW', 'LTC', 1.40, 'BTC', 0.00128, 'complete'),
    ('2026-09-12', 'SideShift', 'BTC', 0.0021, 'XMR', 0.71, 'complete'),
    ('2026-08-11', 'Trocador', 'LTC', 0.90, 'XMR', 0.47, 'complete'),
    ('2026-07-02', 'Exolix', 'USDT', 150.0, 'XMR', 0.93, 'failed'),
  ];
  static const _contacts = [
    ('Alice', 'LTC', 'ltc1qg82vn3xyhtvpkn3y0c9r4k4w6mhqzs3eu4h5d9'),
    ('Bob', 'LTC', 'LZ3tWqQvKUB2mM5yUCb9TK2nJ7FyYhQ1vX'),
    ('Carol', 'XMR', '48edfHu7V9Z84YzzMa6fUueoELZ9ZRXq9VetWzYGzKt52XU5xvqgzYnDK9URnRoJMk1j8nLwEVsaSWJ4fhdUyZijBGUicoD'),
    ('Dave Exchange', 'BTC', 'bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq'),
  ];

  /// Every tool call since the last [drainCalls], as {name, args}.
  final List<Map<String, dynamic>> _calls = [];

  List<Map<String, dynamic>> drainCalls() {
    final copy = List<Map<String, dynamic>>.from(_calls);
    _calls.clear();
    return copy;
  }

  void _record(String name, [Map<String, dynamic> args = const {}]) => _calls.add({
        'name': name,
        'args': {
          for (final entry in args.entries)
            if (entry.value != null) entry.key: entry.value,
        },
      });

  @override
  String get coin => 'LTC';

  @override
  DateTime get now => _today;

  static String _d(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _usd(double x) {
    final fixed = (x * _price).toStringAsFixed(2);
    final parts = fixed.split('.');
    final grouped = parts[0].replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
    return '\$$grouped.${parts[1]}';
  }

  static String _g(double v) {
    var s = v.toStringAsFixed(8);
    s = s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
    return s;
  }

  static String _periodId(AskCakeRange range) => switch (range.label) {
        'today' => 'today',
        'yesterday' => 'yesterday',
        'the last 7 days' => 'last_7_days',
        'the last 30 days' => 'last_30_days',
        'the last 90 days' => 'last_90_days',
        'this month' => 'this_month',
        'last month' => 'last_month',
        'this year' => 'this_year',
        'last year' => 'last_year',
        'all time' => 'all_time',
        _ => range.label,
      };

  static String _label(AskCakeRange range) => '${_d(range.start)} to ${_d(range.end)}';

  static bool _in(String date, AskCakeRange range) => range.contains(DateTime.parse(date));

  @override
  Future<String> walletOverview() async {
    _record('get_wallet_overview');
    return 'Current wallet: Main Litecoin (LTC). Balance: $_balance LTC (about ${_usd(_balance)}). '
        'LTC price: \$$_price. Other wallets on this device (balances unknown until opened): '
        'Savings (Monero), Daily BTC (Bitcoin), Stables (Ethereum).';
  }

  @override
  String activitySummary(AskCakeRange range) {
    _record('get_activity_summary', {'period': _periodId(range)});
    final rows = _txs.where((t) => _in(t.$1, range)).toList();
    if (rows.isEmpty) return 'No transactions between ${_d(range.start)} and ${_d(range.end)}.';
    final sent = rows.where((t) => !t.$2).toList();
    final received = rows.where((t) => t.$2).toList();
    final ts = sent.fold<double>(0, (s, t) => s + t.$3);
    final tr = received.fold<double>(0, (s, t) => s + t.$3);
    final fees = sent.fold<double>(0, (s, t) => s + t.$4);
    final net = tr - ts - fees;
    final lines = [
      'Summary for the period (${_d(range.start)} to ${_d(range.end)}):',
      '- Sent: ${ts.toStringAsFixed(4)} LTC (${_usd(ts)}) in ${sent.length} transactions',
      '- Received: ${tr.toStringAsFixed(4)} LTC (${_usd(tr)}) in ${received.length} transactions',
      '- Network fees paid: ${fees.toStringAsFixed(5)} LTC (${_usd(fees)})',
      '- Net change: ${net >= 0 ? '+' : ''}${net.toStringAsFixed(4)} LTC (${_usd(net)})',
    ];
    if (sent.isNotEmpty) {
      final m = sent.reduce((a, b) => a.$3 >= b.$3 ? a : b);
      lines.add('- Largest outgoing: ${m.$3} LTC on ${m.$1} (${m.$5})');
    }
    if (received.isNotEmpty) {
      final m = received.reduce((a, b) => a.$3 >= b.$3 ? a : b);
      lines.add('- Largest incoming: ${m.$3} LTC on ${m.$1} (${m.$5})');
    }
    return lines.join('\n');
  }

  @override
  String activityPatterns(AskCakeRange range) {
    _record('get_activity_patterns', {'period': _periodId(range)});
    return askCakePatterns([
      for (final t in _txs)
        if (_in(t.$1, range)) DateTime.parse(t.$1)
    ], range);
  }

  @override
  String transactions(AskCakeRange range, {String? direction, String? search, int? limit}) {
    _record('get_transactions',
        {'direction': direction, 'period': _periodId(range), 'search': search, 'limit': limit});
    var rows = _txs.where((t) => _in(t.$1, range)).toList();
    if (direction == 'incoming') rows = rows.where((t) => t.$2).toList();
    if (direction == 'outgoing') rows = rows.where((t) => !t.$2).toList();
    if (search != null && search.isNotEmpty) {
      rows = rows.where((t) => askCakeNoteMatches(t.$5, search)).toList();
    }
    final what = '${direction == null || direction == 'all' ? '' : '$direction '}transactions'
        '${search != null && search.isNotEmpty ? " matching '$search'" : ''}';
    if (rows.isEmpty) return 'No $what from ${_label(range)}.';
    final ts = rows.where((t) => !t.$2).fold<double>(0, (s, t) => s + t.$3);
    final tr = rows.where((t) => t.$2).fold<double>(0, (s, t) => s + t.$3);
    return [
      '${rows.length} $what from ${_label(range)}. Total sent ${ts.toStringAsFixed(4)} LTC (${_usd(ts)}), '
          'total received ${tr.toStringAsFixed(4)} LTC (${_usd(tr)}). Newest first:',
      for (final t in rows.take(limit ?? 10))
        '- ${t.$1} ${t.$2 ? 'received' : 'sent'} ${t.$3} LTC (${_usd(t.$3)})'
            '${t.$4 > 0 ? ' fee ${t.$4} LTC' : ''} note: ${t.$5}',
    ].join('\n');
  }

  @override
  Future<String> swaps(AskCakeRange range) async {
    _record('get_swaps', {'period': _periodId(range)});
    final rows = _swaps.where((s) => _in(s.$1, range)).toList();
    if (rows.isEmpty) return 'No swaps from ${_label(range)}.';
    final providers = <String, int>{};
    final got = <String, double>{};
    for (final s in rows) {
      providers[s.$2] = (providers[s.$2] ?? 0) + 1;
      if (s.$7 == 'complete') got[s.$5] = (got[s.$5] ?? 0) + s.$6;
    }
    final ranked = providers.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final failed = rows.where((s) => s.$7 != 'complete').toList();
    return [
      '${rows.length} swaps from ${_label(range)}, newest first:',
      for (final s in rows)
        '- ${s.$1} ${s.$4} ${s.$3} -> ${s.$6} ${s.$5} via ${s.$2} (${s.$7}) swap ID: FX${1000 + _swaps.indexOf(s)}',
      'Providers used: ${ranked.map((e) => '${e.key} x${e.value}').join(', ')}. Most used: ${ranked.first.key}.',
      'Total received from completed swaps: ${got.entries.map((e) => '${_g(e.value)} ${e.key}').join(', ')}.',
      'Failed swaps: ${failed.length}${failed.isEmpty ? '' : ' (${failed.map((s) => '${s.$1} ${s.$4} ${s.$3} -> ${s.$5} via ${s.$2}').join('; ')})'}',
    ].join('\n');
  }

  @override
  String contacts(String? query) {
    _record('find_contacts', {'query': query});
    final q = (query ?? '').trim().toLowerCase();
    final rows = q.isEmpty ? _contacts : _contacts.where((c) => c.$1.toLowerCase().contains(q)).toList();
    if (rows.isEmpty) return "No contact matching '$query'.";
    return rows.map((c) => '- ${c.$1} (${c.$2}): ${c.$3}').join('\n');
  }

  @override
  String? contactNamedIn(String text) {
    final lower = text.toLowerCase();
    final found = _contacts
        .where((c) => RegExp('\\b${RegExp.escape(c.$1.toLowerCase())}\\b').hasMatch(lower))
        .map((c) => c.$1)
        .toSet();
    return found.length == 1 ? found.first : null;
  }

  @override
  AskCakeToolResult addContact({required String name, required String address, String? coin}) {
    final ticker = (coin == null || coin.isEmpty ? 'LTC' : coin).toUpperCase();
    _record('add_contact', {'name': name, 'address': address, 'coin': ticker});
    return AskCakeToolResult(
        "Opened the Add Contact screen prefilled with name '$name', $ticker address $address. The user must tap Save to confirm.");
  }

  @override
  AskCakeToolResult send({required String recipient, required double amount, required bool fiat}) {
    _record('send_payment', {'recipient': recipient, 'amount': '$amount', 'amount_unit': fiat ? 'fiat' : 'coin'});
    var value = amount;
    if (fiat) value = double.parse((amount / _price).toStringAsFixed(5));
    final r = recipient.trim();
    final match = _contacts
        .where((c) => c.$1.toLowerCase() == r.toLowerCase() || c.$1.toLowerCase().startsWith(r.toLowerCase()))
        .toList();
    String who;
    if (r.isNotEmpty && match.isNotEmpty) {
      final c = match.first;
      if (c.$2 != 'LTC') {
        return AskCakeToolResult(
            'Contact ${c.$1} only has a ${c.$2} address, which cannot receive LTC from this wallet. Nothing was opened.');
      }
      who = '${c.$1} (${c.$3})';
    } else if (r.length > 25 && RegExp(r'^(ltc1|l|m)', caseSensitive: false).hasMatch(r)) {
      who = r;
    } else {
      return AskCakeToolResult(
          "No contact named '$recipient' and it is not a valid LTC address. Ask the user for the address.");
    }
    if (value > _balance) {
      return AskCakeToolResult(
          'Insufficient balance: wallet has $_balance LTC but $value LTC was requested. Nothing was opened.');
    }
    return AskCakeToolResult(
        'Opened the Send screen prefilled with $value LTC (${_usd(value)}) to $who. Nothing has been sent; the user must review and confirm.');
  }

  @override
  AskCakeToolResult receive() {
    _record('show_receive_address');
    return const AskCakeToolResult('Opened the Receive screen. Current receive address: $_address');
  }
}

/// A fictional app around the fixture wallet, for the self-test. It records
/// what the engine asked for and never touches real settings or screens.
class AskCakeFixtureApp implements AskCakeApp {
  AskCakeFixtureApp(this._tools);

  final AskCakeFixtureTools _tools;

  static const _needsScreen = {'address_lookups', 'block_explorer_apis', 'background_sync'};

  @override
  List<AskCakeAccount> accounts() => const [];

  @override
  String status() {
    _tools._record('app_status');
    return 'Wallet: Main (Litecoin)\nSync: Synchronized\nNode: ltc-electrum.cakewallet.com:50002\nTor: off\nDisplay currency: USD';
  }

  @override
  Future<String> price(String? asset, String? range) async {
    _tools._record('price', {'asset': asset ?? '', 'range': range ?? ''});
    return '${asset ?? 'LTC'} price now: USD 92.40${range == null ? '' : '\nOver the chosen period ($range): up 4.2% (from USD 88.68 to USD 92.40)'}';
  }

  @override
  Future<String> lightningInfo() async {
    _tools._record('lightning_info');
    return 'Lightning address: fixture@cake.cash\nLightning balance: 0.00042 BTC';
  }

  @override
  String tokens() {
    _tools._record('tokens');
    return 'This Litecoin wallet holds no tokens.';
  }

  @override
  Future<String> fees() async {
    _tools._record('fees');
    return 'Default fee level for Litecoin: Medium\nSlow: 1 sat/vB\nMedium: 2 sat/vB\nFast: 5 sat/vB';
  }

  @override
  AskCakeToolResult setting(String setting, String value) {
    _tools._record('setting', {'setting': setting, 'value': value});
    final description = AskCakeGuards.describeSetting(setting, value);
    final off = const {'off', 'false', 'disable', 'disabled', 'no'}.contains(value.toLowerCase());
    if (_needsScreen.contains(setting) || (off && const {'tor', 'prevent_screenshots', 'auto_generate_addresses'}.contains(setting))) {
      return AskCakeToolResult('To $description, use the settings screen.',
          action: const AskCakeOpenRouteAction('/settings', 'Open that setting'));
    }
    return AskCakeToolResult('Ready to $description. Nothing changes until you tap the button.',
        action: AskCakeApplySettingAction(setting: setting, value: value, label: description));
  }

  @override
  String? walletMentionedIn(String message) => null;

  @override
  AskCakeToolResult switchWallet(String? name) {
    _tools._record('switch_wallet', {'name': name ?? ''});
    return AskCakeToolResult('Ready to switch to ${name ?? '?'}.',
        action: name == null ? null : AskCakeSwitchWalletAction(name));
  }

  @override
  AskCakeToolResult receive({String? addressType, bool fresh = false, String? amount}) {
    _tools._record('receive_typed', {'address_type': addressType ?? '', 'new': fresh});
    return AskCakeToolResult('Opening Receive.',
        action: AskCakeReceiveAction(lightning: addressType == 'lightning', addressType: addressType));
  }

  @override
  AskCakeToolResult? open(String tool, Map<String, dynamic> details) {
    _tools._record('open', {'tool': tool, ...details}..remove('_text'));
    return AskCakeToolResult('Opening ${tool.replaceAll('_', ' ')}.', action: AskCakeOpenRouteAction('/$tool', 'Open'));
  }
}
