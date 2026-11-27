import 'dart:convert';

import 'package:cake_wallet/ask_cake/ask_cake_app.dart';
import 'package:cake_wallet/ask_cake/ask_cake_docs.dart';
import 'package:cake_wallet/ask_cake/ask_cake_guards.dart';
import 'package:cake_wallet/ask_cake/ask_cake_model.dart';
import 'package:cake_wallet/ask_cake/ask_cake_router.dart';
import 'package:cake_wallet/ask_cake/ask_cake_tools.dart';

/// A value shown under a reply with a button that copies it.
class AskCakeCopyable {
  const AskCakeCopyable(this.label, this.value);

  final String label;
  final String value;
}

class AskCakeReply {
  const AskCakeReply(this.text,
      {this.action,
      this.route = '',
      this.elapsed = Duration.zero,
      this.sourceUrl,
      this.options = const [],
      this.copyables = const [],
      this.routerMs,
      this.routerConfidence,
      this.dataStart,
      this.dataEnd});

  /// Where in [text] the figures read from the wallet begin and end, when the
  /// reply has any: the chat lays that stretch out as cards instead of prose.
  final int? dataStart;
  final int? dataEnd;

  final String text;
  final AskCakeAction? action;

  /// Which tool was chosen and with what inputs; shown in the demo UI.
  final String route;
  final Duration elapsed;

  /// Docs page a help answer was drawn from, when it was.
  final String? sourceUrl;

  /// Pre-canned replies to a question in [text]; empty when nothing was asked.
  final List<AskCakeOption> options;

  /// Values the user may need to hand to support (swap IDs), each shown with a copy button.
  final List<AskCakeCopyable> copyables;

  /// How sure the trained router was of its choice (0 to 1), when it reports that.
  final double? routerConfidence;

  /// Time the trained router took for this message, when it was used.
  final int? routerMs;
}

/// Turns a chat message into a wallet answer or a prepared action.
///
/// A small on-device model is unreliable when left to drive tools freely (it
/// skips tools and invents figures), so the model is only asked for three
/// narrow things: pick one tool from a fixed list, pull a few fields out of the
/// user's wording, and phrase an answer from data it is handed. Dates, amounts
/// and addresses are parsed or cross-checked in code against what the user
/// actually typed, and every action stops at a screen the user must confirm.
class AskCakeEngine {
  AskCakeEngine(this._model, this._tools, {AskCakeRouter? router, AskCakeGuards? guards, AskCakeApp? app})
      : _trained = router,
        _guards = guards,
        _app = app;

  /// The rest of the app: settings, prices, other wallets and screens.
  final AskCakeApp? _app;

  final AskCakeLanguageModel _model;
  final AskCakeToolbox _tools;

  /// The trained on-device router. When present it chooses the capability and
  /// extracts the details, and Apple's model is only used to phrase answers.
  final AskCakeRouter? _trained;
  final AskCakeGuards? _guards;

  /// What the trained router understood for the message being handled.
  AskCakeLabel? _label;
  int? _routerMs;
  double? _routerConfidence;

  /// A reading of the current message the user confirmed with a reply button; used instead of asking the router again.
  AskCakeLabel? _forced;

  String? _routerSession;
  final List<String> _userTurns = [];
  String? _pendingTool;
  bool _previousWasSetting = false;
  String? _lastPerson;

  /// The user messages that make up the action being prepared right now: the
  /// request itself plus any answers to follow-up questions about it. Amounts
  /// and addresses are only ever taken from these, never from older turns.
  final List<String> _actionTurns = [];

  static const _toolNames = [
    'wallet_overview',
    'activity_totals',
    'transactions',
    'swaps',
    'contacts',
    'add_contact',
    'send_payment',
    'receive',
    'seed_or_keys',
    'investment_advice',
    'app_help',
    'general_question',
  ];

  static const _toolGuide = '''
Pick the one tool for the user's latest message:
- wallet_overview: balance, what the coins are worth, current coin price, which wallets exist
- activity_totals: totals for a period: how much spent, received, saved, fees paid, net change, biggest payment, "how am I doing"
- transactions: list or find specific transactions; anything about a named person, merchant or keyword (Alice, VPN); "last N transactions"; what was received/sent in a month; total sent to a person
- swaps: swap/exchange history, providers, failed swaps, coins obtained from swaps
- contacts: look up or list address book contacts and their addresses
- add_contact: save a new contact
- send_payment: send, pay or transfer coins to someone
- receive: show my address / get paid / receive
- seed_or_keys: seed phrase, private keys, backup words
- investment_advice: should I buy/sell/hold, price predictions
- app_help: how to do something in Cake Wallet or how a feature works: settings, backup and restore, PIN and 2FA, nodes and syncing, hardware wallets, supported coins and platforms, installing, Cake Pay, Cupcake, swap problems, contacting support
- general_question: greetings, thanks, anything else
Examples: "Add Grace to my contacts" -> add_contact. "save this address as Tom" -> add_contact. "What's Bob's address?" -> contacts. "pay bob half a litecoin" -> send_payment. "What's my address?" -> receive. "what's the LTC price" -> wallet_overview. "Did I save or spend more?" -> activity_totals. "What was my biggest payment?" -> activity_totals. "how do I back up my wallet" -> app_help. "is there a Windows version" -> app_help. "show my swaps" -> swaps, but "why did my swap fail" -> app_help.
''';

  String get _today => _date(_tools.now);

  static String _date(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// The routing session accumulates every turn, and replies slow down as it
  /// grows (2 s to 15 s over ten turns in the simulator), so it is replaced
  /// every few turns, carrying only the last two user messages forward.
  static const _routerTurnLimit = 6;
  int _routerTurns = 0;

  Future<String> _router() async {
    final existing = _routerSession;
    if (existing != null && _routerTurns < _routerTurnLimit) return existing;
    if (existing != null) await _model.disposeSession(existing);
    final earlier = _userTurns.length > 1
        ? _userTurns.sublist(0, _userTurns.length - 1).reversed.take(2).toList().reversed.join(' | ')
        : '';
    _routerTurns = 0;
    return _routerSession = await _model.createSession(
        'You are Ask Cake, the assistant inside Cake Wallet, a self-custodial crypto wallet app. '
        'Today is $_today. The open wallet holds ${_tools.coin}. '
        'You help in small steps: choosing a tool, then filling in its inputs from what the user wrote. '
        'Resolve follow-ups ("him", "that", "make it 0.2", "and this month?") from the conversation. '
        'Never invent names, amounts or addresses.\n$_toolGuide'
        '${earlier.isEmpty ? '' : '\nEarlier user messages: $earlier'}');
  }

  Future<void> reset() async {
    final session = _routerSession;
    _routerSession = null;
    _userTurns.clear();
    _pendingTool = null;
    _lastPerson = null;
    _actionTurns.clear();
    _routerTurns = 0;
    if (session != null) await _model.disposeSession(session);
  }

  Future<AskCakeReply> ask(String message, {bool asHelp = false}) async {
    final watch = Stopwatch()..start();
    AskCakeReply reply;
    try {
      reply = await _handle(message.trim(), asHelp: asHelp);
    } on AskCakeModelException catch (e) {
      if (e.code == 'context') {
        // The router session filled the context window; start over and retry once.
        final turns = List<String>.from(_userTurns)..removeLast();
        await reset();
        _userTurns.addAll(turns.length > 2 ? turns.sublist(turns.length - 2) : turns);
        try {
          reply = await _handle(message.trim());
        } on AskCakeModelException catch (e) {
          reply = AskCakeReply(_errorText(e), route: 'error:${e.code}');
        }
      } else {
        reply = AskCakeReply(_errorText(e), route: 'error:${e.code}');
      }
    }
    return AskCakeReply(reply.text,
        action: reply.action,
        route: reply.route,
        elapsed: watch.elapsed,
        sourceUrl: reply.sourceUrl,
        options: reply.options,
        copyables: reply.copyables,
        routerMs: _routerMs,
        routerConfidence: _routerConfidence,
        dataStart: reply.dataStart,
        dataEnd: reply.dataEnd);
  }

  /// The user tapped one of the reply buttons under a question.
  Future<AskCakeReply> choose(AskCakeOption option) async {
    switch (option.kind) {
      case 'confirmSetting':
        return _changeSetting(option.payload ?? const {'tool': 'change_setting'});
      case 'openSettings':
        return const AskCakeReply('Opening Settings so you can change it yourself.',
            action: AskCakeOpenPageAction('settings', 'Open Settings'), route: 'open_settings');
      case 'confirmTool':
        // The user confirmed what the router was unsure about: run the same message with that reading.
        final payload = option.payload ?? const {};
        final text = payload['_text'] as String? ?? '';
        _forced = {...payload}..remove('_text');
        if (_userTurns.isNotEmpty) _userTurns.removeLast();
        return ask(text);
      case 'answerInstead':
        return ask(option.payload?['_text'] as String? ?? '', asHelp: true);
      default:
        return const AskCakeReply('No problem. Tell me another way what you would like to do.', route: 'dismissed');
    }
  }

  /// Requests that open or prepare something, in the words used to ask "Did you mean ...?".
  static const _actionPhrases = {
    'send_payment': 'prepare a payment',
    'swap': 'start a swap',
    'buy': 'buy crypto',
    'sell': 'sell crypto',
    'add_contact': 'save a new contact',
    'change_setting': 'change a setting',
    'switch_wallet': 'switch to another wallet',
    'manage_nodes': 'change the node',
    'rescan': 'rescan this wallet',
    'move_funds': 'move funds',
    'sign_message': 'sign or verify a message',
    'backup': 'make a backup',
    'manage_wallets': 'create or restore a wallet',
    'walletconnect': 'connect to a dApp',
    'export_data': 'export your transactions',
    'set_lightning_username': 'set your Lightning username',
    'receive': 'show a receive address',
  };

  /// Below this the router's choice of an action is wrong more often than right
  /// (measured on the held-out sets), so the user is asked instead.
  static const _confidentEnough = 0.9;

  /// Below this, three of four action guesses on the held-out sets were wrong.
  static const _worthAsking = 0.7;

  /// Slots for the current message: taken from the trained router when it ran,
  /// otherwise extracted by Apple's model in the routing session.
  Future<Map<String, dynamic>> _slots(String prompt, String name, List<AskCakeField> fields,
      {String? instructions, String? text}) async {
    final label = _label;
    if (label != null) {
      return {
        ...label,
        if (label['ticker'] != null) 'coin': label['ticker'],
        if (label['fiat'] == true) 'amountIsDollars': true,
      };
    }
    if (instructions != null) {
      final session = await _model.createSession(instructions);
      try {
        return await _model.respondStructured(session, text ?? prompt, name, fields);
      } finally {
        await _model.disposeSession(session);
      }
    }
    return _model.respondStructured(await _router(), prompt, name, fields);
  }

  AskCakeReply _changeSetting(AskCakeLabel label) {
    final app = _app;
    final setting = label['setting'];
    if (app == null || setting is! String) return _understood(label);
    final result = app.setting(setting, '${label['value'] ?? ''}');
    return AskCakeReply(result.text, action: result.action, route: 'change_setting ${jsonEncode(label)}');
  }

  /// A capability the router recognised that this test build cannot carry out yet.
  AskCakeReply _understood(AskCakeLabel label) {
    final tool = label['tool'] as String? ?? '';
    final details = Map<String, dynamic>.from(label)..removeWhere((k, _) => k == 'tool' || k.startsWith('_'));
    final what = tool == 'change_setting' && details['setting'] is String
        ? AskCakeGuards.describeSetting(details['setting'] as String, details['value'])
        : '${tool.replaceAll('_', ' ')}${details.isEmpty ? '' : ' (${details.entries.map((e) => '${e.key}: ${e.value}').join(', ')})'}';
    return AskCakeReply('I understood this as: $what. That is not connected in this test build yet.',
        route: 'understood ${jsonEncode(label)}');
  }

  String _errorText(AskCakeModelException e) => switch (e.code) {
        'guardrail' =>
          'The on-device model declined that request. Try rephrasing it, or use the regular wallet screens.',
        'unavailable' => 'The on-device model is not available right now.',
        _ => 'Something went wrong while thinking about that. Please try again.',
      };

  Future<AskCakeReply> _handle(String turn, {bool asHelp = false}) async {
    _label = null;
    _routerMs = null;
    _routerConfidence = null;
    if (asHelp) {
      if (_userTurns.isNotEmpty) _userTurns.removeLast();
      _userTurns.add(turn);
      _forced = null;
      return _helpOrGeneral(turn, 'app_help');
    }
    // A pasted recovery phrase or key is dropped before anything else sees it.
    if (_guards?.secretInput(turn) ?? false) {
      return const AskCakeReply(AskCakeGuards.secretInputWarning, route: 'secret_input');
    }
    final earlier = List<String>.from(_userTurns);
    _userTurns.add(turn);

    String tool;
    final pending = _pendingTool;
    _pendingTool = null;
    var answering = pending != null && _looksLikeAnswer(turn);
    // Two requests are plain enough to recognise by their wording, and the
    // trained router has no capability for either: the QR scanner, and
    // questions about when the user transacts.
    if (!answering) {
      AskCakeReply? direct;
      if (AskCakeGuards.isScanRequest(turn)) {
        direct = const AskCakeReply(
            'Opening the scanner. Point it at a QR code: a payment request opens Send for you to review, '
            'and a WalletConnect code starts pairing.',
            action: AskCakeOpenPageAction('scanner', 'Open scanner'),
            route: 'scan');
      } else if (AskCakeGuards.isAboutMyHabits(turn)) {
        final range = parseRange(turn, _tools.now);
        direct = await _answer(turn, _tools.activityPatterns(range), 'activity_patterns ${range.label}');
      }
      if (direct != null) {
        _actionTurns
          ..clear()
          ..add(turn);
        _previousWasSetting = false;
        return direct;
      }
    }
    final trained = _trained;
    AskCakeLabel? routed;
    if (trained != null) {
      final watch = Stopwatch()..start();
      final forced = _forced;
      _forced = null;
      routed = forced ??
          await trained.route(
              coin: _tools.coin, earlier: earlier, message: turn, pendingTool: answering ? pending : null);
      _routerMs = watch.elapsedMilliseconds;
      // "Swap to USDT" is an order to open Swap whatever the router made of it;
      // the coins it names fill any the router left out.
      final order = forced == null && !answering ? AskCakeGuards.swapOrder(turn) : null;
      if (order != null) {
        routed = {
          if (routed['tool'] == 'swap') ...routed,
          'tool': 'swap',
          if (routed['tool'] != 'swap' || routed['from'] == null) 'from': order.from,
          if (routed['tool'] != 'swap' || routed['to'] == null) 'to': order.to,
          '_conf': 1.0,
        }..removeWhere((_, value) => value == null);
      }
      final confidence = routed['_conf'];
      _routerConfidence = confidence is num ? confidence.toDouble() : null;
      // An action the router is unsure about is offered as a question first.
      final unsure = routed['tool'];
      if (forced == null &&
          !answering &&
          _routerConfidence != null &&
          _routerConfidence! < _confidentEnough &&
          _actionPhrases.containsKey(unsure) &&
          AskCakeGuards.backstop(turn, unsure as String) == unsure) {
        // Well below that, the guess is not worth showing: say so instead of asking about it.
        if (_routerConfidence! < _worthAsking) {
          return const AskCakeReply(
              'I\'m not sure what you would like me to do. Could you say it another way?',
              route: 'unsure');
        }
        return AskCakeReply('Did you mean: ${_actionPhrases[unsure]}?',
            options: [
              AskCakeOption('Yes', 'confirmTool', payload: {...routed, '_text': turn, '_conf': 1.0}),
              AskCakeOption('No, just answer', 'answerInstead', payload: {'_text': turn}),
            ],
            route: 'ask_user unsure ${jsonEncode({'tool': unsure})}');
      }
      // The router was told what the app is waiting for. If it still reads the
      // message as a different request, it is one, unless the message is a bare
      // detail (an address, or a word or two such as a name or an amount).
      if (answering &&
          routed['tool'] != pending &&
          addressIn(turn) == null &&
          turn.trim().split(RegExp(r'\s+')).length > 2) {
        answering = false;
      }
    }
    if (answering) {
      _actionTurns.add(turn);
    } else {
      _actionTurns
        ..clear()
        ..add(turn);
    }
    if (trained != null) {
      var label = routed!;
      tool = answering ? pending! : AskCakeGuards.backstop(turn, label['tool'] as String? ?? 'general_question');
      label = {...label, 'tool': tool};
      // Only a settings request just before this one can supply the setting for
      // a follow-up ("turn it back off"); anything else has to name it again.
      // "Switch to <a wallet's own name>" is a wallet switch even when the
      // router reads the unfamiliar name as a setting or a question.
      if (const {'change_setting', 'general_question', 'app_help'}.contains(tool) &&
          RegExp(r'^\s*(please\s+)?(switch|change|go|open|use|load)\b', caseSensitive: false).hasMatch(turn)) {
        final wallet = _app?.walletMentionedIn(turn);
        if (wallet != null) {
          tool = 'switch_wallet';
          label = {'tool': tool, 'name': wallet};
        }
      }
      // A worry about who can see the connection is about Tor. The message does
      // not say "Tor", so the setting check below would otherwise swap in whichever
      // setting a stray word names ("hide" -> hide balance). Ask instead.
      if (tool == 'change_setting' &&
          AskCakeGuards.isAboutConnectionPrivacy(turn) &&
          !RegExp(r'\btor\b', caseSensitive: false).hasMatch(turn)) {
        return AskCakeReply('Did you mean: turn Tor on?',
            options: const [
              AskCakeOption('Yes, turn Tor on', 'confirmSetting',
                  payload: {'tool': 'change_setting', 'setting': 'tor', 'value': 'on'}),
              AskCakeOption('Open Settings', 'openSettings'),
              AskCakeOption('No', 'dismiss'),
            ],
            route: 'ask_user ${jsonEncode({'tool': 'change_setting', 'setting': 'tor', 'value': 'on'})}');
      }
      final recent = [if (_previousWasSetting) ...earlier.reversed.take(1), turn].join(' \n ');
      _previousWasSetting = tool == 'change_setting';
      final grounded = AskCakeGuards.groundSetting(recent, label, latest: turn);
      if (grounded.question != null && !AskCakeGuards.isQuestion(turn)) {
        return AskCakeReply(grounded.question!.text,
            options: grounded.question!.options, route: 'ask_user ${jsonEncode(label)}');
      }
      // A question that never names the setting is a help question, not a request to change something.
      label = grounded.label ?? {'tool': 'app_help'};
      tool = label['tool'] as String;
      _label = label;
      // Three corrections for router slips seen on the phone; each can only move
      // between answering from docs, answering from the user's data, and a prefilled Send.
      const ownData = {'swaps', 'tokens', 'transactions', 'wallet_overview', 'contacts', 'activity_totals'};
      if (ownData.contains(tool) && AskCakeGuards.isAboutTheApp(turn)) {
        tool = 'app_help';
        _label = {'tool': tool};
      } else if ((tool == 'app_help' || tool == 'general_question') && AskCakeGuards.isAboutMyWallets(turn)) {
        // "Do I have a Monero wallet?": the wallet list answers it; the model alone guesses.
        tool = 'wallet_overview';
        _label = {'tool': tool};
      } else if ((tool == 'app_help' || tool == 'general_question') && AskCakeGuards.isRecapRequest(turn)) {
        tool = 'activity_totals';
        _label = {'tool': tool};
      } else if (tool == 'fees' && AskCakeGuards.isAboutFeesPaid(turn)) {
        tool = 'activity_totals';
        _label = {'tool': tool};
      } else if (tool == 'app_help' && _app != null && AskCakeGuards.isAboutMySync(turn)) {
        // "my wallet won't sync": show the sync state and node first, the help page after.
        tool = 'app_status';
        _label = {'tool': tool};
      } else if (tool == 'transactions' && RegExp(r'\bswap(s|ped|ping)?\b').hasMatch(turn.toLowerCase())) {
        tool = 'swaps';
        _label = {'tool': tool};
      } else if ((tool == 'app_help' || tool == 'general_question') &&
          AskCakeGuards.isProblem(turn) &&
          !AskCakeGuards.isQuestion(turn) &&
          RegExp(r'\bmy (last |latest |recent |first )?(swap|trade|exchange)\b').hasMatch(turn.toLowerCase())) {
        // "my swap is stuck": the user's own swaps and their IDs first, then where to get help.
        tool = 'swaps';
        _label = {'tool': tool};
      } else if ((tool == 'app_help' || tool == 'general_question') && AskCakeGuards.isAboutMyActivity(turn)) {
        // Past activity: a swap question goes to the swap history, anything else to transactions.
        tool = RegExp(r'\bswap(s|ped|ping)?\b').hasMatch(turn.toLowerCase()) ? 'swaps' : 'transactions';
        _label = null; // let the details be read afresh for the search
      } else if (tool == 'fees' &&
          RegExp(r'\b(send|pay|transfer)\b').hasMatch(turn.toLowerCase()) &&
          _tools.contactNamedIn(turn) != null) {
        tool = 'send_payment';
        _label = {'tool': tool, 'recipient': _tools.contactNamedIn(turn)};
      }
    } else if (answering) {
      tool = pending!;
      _routerTurns++;
    } else {
      _routerTurns++;
      final choice = await _model.respondStructured(await _router(), 'User: $turn\nPick the tool.', 'Choice',
          const [AskCakeField.choice('tool', _toolNames)]);
      tool = choice['tool'] as String? ?? 'general_question';
    }

    final range = parseRange(turn, _tools.now);

    // Figures come from the account that is open. A question that names another
    // account of this wallet gets that account's balance and a button to switch.
    const perAccount = {'wallet_overview', 'activity_totals', 'transactions', 'receive', 'send_payment', 'switch_wallet'};
    if (perAccount.contains(tool)) {
      final other = _otherAccount(turn, switching: tool == 'switch_wallet');
      if (other != null) return other;
    }

    switch (tool) {
      case 'wallet_overview':
        return _ownRecord(turn, await _answer(turn, await _tools.walletOverview(), tool));
      case 'activity_totals':
        return _answer(turn, _tools.activitySummary(range), '$tool ${range.label}');
      case 'transactions':
        final query = await _slots(
            'Fill in the transaction search for the user\'s request. Leave out anything they did not mention.',
            'TransactionSearch', const [
          AskCakeField.string('search',
              description: 'Person, merchant or keyword mentioned, e.g. Alice or VPN'),
          AskCakeField.integer('limit',
              description: 'Number of rows if the user asked for a specific count'),
        ]);
        // "was there a refund": the word itself is the search when the model picked none.
        final search = _groundedWord(query['search'], turn) ??
            (RegExp(r'\brefund', caseSensitive: false).hasMatch(turn) ? 'refund' : null);
        final direction = parseDirection(turn);
        // "last 5 transactions": the count is read from the words when the router left it out.
        final counted = RegExp(r'\b(?:last|latest|recent|newest|past|top)\s+(\d{1,2})\b|\b(\d{1,2})\s+(?:most recent |latest |last |recent )?(?:transactions?|payments?|txs?)\b')
            .firstMatch(turn.toLowerCase());
        final limit = query['limit'] is int && RegExp(r'\d').hasMatch(turn)
            ? query['limit'] as int
            : int.tryParse(counted?.group(1) ?? counted?.group(2) ?? '');
        return _ownRecord(
            turn,
            await _answer(
                turn,
                _tools.transactions(range, direction: direction, search: search, limit: limit),
                '$tool ${range.label} dir=${direction ?? 'all'} search=${search ?? '-'} limit=${limit ?? '-'}'));
      case 'swaps':
        return _ownRecord(turn, await _answer(turn, await _tools.swaps(range), '$tool ${range.label}'));
      case 'contacts':
        final query = await _slots('Which contact name is the user asking about, if any?', 'ContactQuery', const [
          AskCakeField.string('name', description: 'Name asked about; omit to list all'),
        ]);
        final name = _groundedWord(query['name'], turn);
        final data = _tools.contacts(name);
        if (name == null) return AskCakeReply('Your contacts:\n$data', route: tool);
        _lastPerson = name;
        return _answer(turn, data, '$tool name=$name');
      case 'add_contact':
        return _addContact(turn);
      case 'send_payment':
        return _send(turn);
      case 'receive':
        final type = _label?['address_type'] as String?;
        final fresh = _label?['new'] == true;
        final result = _app != null && (type != null || fresh)
            ? _app.receive(addressType: type, fresh: fresh, amount: _label?['amount']?.toString())
            : _tools.receive();
        return AskCakeReply(result.text, action: result.action, route: '$tool type=${type ?? '-'} new=$fresh');
      case 'price':
        // A range only counts when this message mentions a period; otherwise it is the current price.
        final asked = AskCakeGuards.mentionsPeriod(turn)
            ? AskCakeGuards.priceRange(turn, _label?['range'] as String?)
            : null;
        final asset = _label?['asset'] as String?;
        final route = 'price asset=${asset ?? '-'} range=${asked ?? 'now'}';
        if (_app == null) return _answer(turn, await _tools.walletOverview(), route);
        return _answer(turn, await _app.price(asset, asked), route);
      case 'app_status':
        if (_app == null || AskCakeGuards.isHowTo(turn)) return _helpOrGeneral(turn, 'app_help');
        return _ownRecord(turn, await _answer(turn, _app.status(), tool));
      case 'lightning_info':
        if (_app == null) break;
        return _answer(turn, await _app.lightningInfo(), tool);
      case 'tokens':
        if (_app == null) break;
        return _ownRecord(turn, await _answer(turn, _app.tokens(), tool));
      case 'fees':
        if (_app == null) break;
        return _answer(turn, await _app.fees(), tool);
      case 'change_setting':
        if (_label == null) break;
        final label = Map<String, dynamic>.from(_label!);
        if (label['setting'] == 'prevent_screenshots') {
          label['value'] = AskCakeGuards.screenshotProtection(turn, '${label['value'] ?? ''}');
        }
        if (label['setting'] == 'fiat_api' || label['setting'] == 'swap_api') {
          label['value'] = AskCakeGuards.connectionMode(turn, '${label['value'] ?? ''}');
        }
        return _changeSetting(label);
      case 'switch_wallet':
        if (_app == null) break;
        final result = _app.switchWallet(_label?['name'] as String?);
        return AskCakeReply(result.text, action: result.action, route: '$tool name=${_label?['name'] ?? '-'}');
      case 'seed_or_keys':
        return const AskCakeReply(
            'I can\'t see or share seed phrases or private keys. You can view them yourself in Settings under Security and Backup after authenticating.',
            route: 'seed_or_keys');
      case 'investment_advice':
        return const AskCakeReply(
            'I can\'t give investment advice, but I can show you your balances and activity to help you decide.',
            route: 'investment_advice');
      case 'destructive':
        return AskCakeReply(AskCakeGuards.refusals['destructive']!, route: 'destructive');
      case 'app_help':
      case 'general_question':
        return _helpOrGeneral(turn, tool);
    }
    // Everything else opens an existing screen, or is not connected. A question
    // about such a capability is answered from the docs instead.
    final label = _label;
    if (label == null || AskCakeGuards.isQuestion(turn)) return _helpOrGeneral(turn, 'app_help');
    final opened = _app?.open(tool, {...label, '_text': turn});
    if (opened != null) return AskCakeReply(opened.text, action: opened.action, route: 'open ${jsonEncode(label)}');
    return _understood(label);
  }

  /// A reply about another account of the open wallet, when [turn] names one or asks about all of them.
  AskCakeReply? _otherAccount(String turn, {bool switching = false}) {
    final accounts = _app?.accounts() ?? const <AskCakeAccount>[];
    if (accounts.length < 2) return null;
    final text = turn.toLowerCase();
    final current = accounts.where((a) => a.current).firstOrNull;
    bool named(AskCakeAccount a) {
      final name = a.name.toLowerCase().replaceFirst(RegExp(r'\s+account$'), '').trim();
      return name.length >= 3 && RegExp('\\b${RegExp.escape(name)}\\b').hasMatch(text);
    }

    final coin = _tools.coin;
    String line(AskCakeAccount a) => '${a.name}: ${a.balance == null ? 'balance unknown' : '${a.balance} $coin'}';
    final others = accounts.where((a) => !a.current && named(a)).toList();
    if (others.length == 1 && !(current != null && named(current))) {
      final account = others.single;
      final data = line(account);
      final lead = switching ? 'Ready to switch to your ${account.name} account.' : 'That is about your ${account.name} account.';
      final tail = switching
          ? 'It stays in this wallet; only the account changes.'
          : 'I can only read the account that is open${current == null ? '' : ' (${current.name})'}. '
              'Switch to ${account.name} and ask again, and I will answer from it.';
      return AskCakeReply('$lead\n\n$data\n\n$tail',
          action: AskCakeSwitchAccountAction(account.id, account.name),
          route: 'other_account ${account.name}',
          dataStart: lead.length + 2,
          dataEnd: lead.length + 2 + data.length);
    }
    if (!switching &&
        RegExp(r'\b(other|all( of)? (my|the)|every|each|across) accounts?\b|\baccounts\b').hasMatch(text)) {
      final lead = 'This wallet has ${accounts.length} accounts.';
      final data = accounts.map((a) => a.current ? '${line(a)} (open now)' : line(a)).join('\n');
      const tail = 'Transactions and totals come from the account that is open. '
          'To ask about another one, say "switch to" and its name.';
      return AskCakeReply('$lead\n\n$data\n\n$tail',
          route: 'accounts', dataStart: lead.length + 2, dataEnd: lead.length + 2 + data.length);
    }
    return null;
  }

  /// A reply built from the user's own records. Swap IDs in it get copy
  /// buttons, because support asks for them. When the message reports a
  /// problem, the matching help page is linked underneath: the user sees what
  /// the wallet knows first, then where to read on.
  Future<AskCakeReply> _ownRecord(String turn, AskCakeReply reply) async {
    // Unfinished or failed swaps first: those are the ones support is asked about.
    const done = {'complete', 'completed', 'finished', 'traded', 'settled', 'success'};
    final seen = <String>{};
    final open = <String>[];
    final finished = <String>[];
    for (final match in RegExp(r'\(([^)]*)\) swap ID: ([^\s)]+)').allMatches(reply.text)) {
      // A sentence can end right after an ID; the full stop is not part of it.
      final id = match.group(2)!.replaceFirst(RegExp(r'[.,;:!?]+$'), '');
      if (id.isEmpty) continue;
      if (seen.add(id)) (done.contains(match.group(1)!.toLowerCase()) ? finished : open).add(id);
    }
    final ids = [...open, ...finished].take(3).toList();
    final problem = AskCakeGuards.isProblem(turn);
    if (ids.isEmpty && !problem) return reply;
    var text = reply.text;
    String? url;
    if (problem) {
      final hit = (await AskCakeDocs.load()).search(turn);
      url = hit?.url;
      // A "why" question also gets the explanation from the docs, after the user's own record.
      if (hit != null && RegExp(r'^\s*(why|how come)\b', caseSensitive: false).hasMatch(turn)) {
        try {
          final session = await _model.createSession(
              'You are Ask Cake, the help assistant inside the Cake Wallet app. Answer the user\'s question briefly '
              '(1-3 sentences) using only the DOCS excerpts. If DOCS do not answer it, reply with exactly: not sure',
              permissive: true);
          try {
            final explained = (await _model.respond(session, 'DOCS:\n${hit.excerpts}\n\nQuestion: $turn')).trim();
            if (!RegExp(r"^\W*(i'?m |i am )?not sure", caseSensitive: false).hasMatch(explained)) {
              text += '\n\n$explained';
            }
          } finally {
            await _model.disposeSession(session);
          }
        } on AskCakeModelException {
          // The record and the link still stand without the explanation.
        }
      }
      text += ids.isEmpty
          ? '\n\nIf this does not look right, the help page below explains what to check.'
          : '\n\nIf a swap looks wrong, contact support and give them its swap ID (copy it below). '
              'The swap provider handles the trade itself.';
    }
    return AskCakeReply(text,
        // A problem with funds or a swap is what support is for: one tap opens the in-app chat.
        action: reply.action ?? (AskCakeGuards.mayNeedSupport(turn) ? const AskCakeSupportAction() : null),
        route: problem ? '${reply.route} +help' : reply.route,
        sourceUrl: url,
        options: reply.options,
        dataStart: reply.dataStart,
        dataEnd: reply.dataEnd,
        copyables: [for (final id in ids) AskCakeCopyable('Copy swap ID $id', id)]);
  }

  Future<AskCakeReply> _helpOrGeneral(String turn, String tool) async {
    {
        // Help and general questions are answered from the bundled docs when
        // they have something relevant, and from general knowledge otherwise.
        // A short acknowledgement ("thanks", "ok got it", "yes I tried that") is
        // not a question: looking it up in the docs returns an unrelated page.
        final smallTalk = tool == 'general_question' &&
            !AskCakeGuards.isQuestion(turn) &&
            turn.trim().split(RegExp(r'\s+')).length <= 8;
        final hit = smallTalk ? null : (await AskCakeDocs.load()).search(turn);
        if (hit != null) {
          final session = await _model.createSession(
              'You are Ask Cake, the help assistant inside the Cake Wallet app. Answer the user\'s question briefly '
              '(1-4 sentences or short steps) using only the DOCS excerpts. Quote menu names exactly. '
              'If DOCS do not answer the question, say you are not sure and point to the linked page.',
              permissive: true);
          String text;
          try {
            text = (await _model.respond(session, 'DOCS:\n${hit.excerpts}\n\nQuestion: $turn')).trim();
          } finally {
            await _model.disposeSession(session);
          }
          // A help question keeps the docs answer and its link either way.
          final unsure = RegExp(r"^\W*(i'?m |i am )?not sure", caseSensitive: false).hasMatch(text);
          if (tool == 'app_help' || !unsure) {
            return AskCakeReply(text,
                route: '$tool docs',
                sourceUrl: hit.url,
                action: AskCakeGuards.mayNeedSupport(turn) ? const AskCakeSupportAction() : null);
          }
          // A general question the docs only loosely touch: answer from general knowledge instead.
        }
        final session = await _model.createSession(
            'You are Ask Cake, the assistant inside Cake Wallet. Answer briefly in plain text from general knowledge about cryptocurrency and wallets. '
            'You can also look up the user\'s balance, transactions, spending totals, swaps and contacts, and prepare payments or new contacts for them to confirm.');
        try {
          return AskCakeReply(await _model.respond(session, turn),
              route: '$tool general',
              action: AskCakeGuards.mayNeedSupport(turn) ? const AskCakeSupportAction() : null);
        } finally {
          await _model.disposeSession(session);
        }
    }
  }

  /// Wallet figures are shown exactly as the tool produced them. The model may
  /// add one lead-in sentence, but only if every number in it also appears in
  /// the data: the smaller on-device model recomputes and misquotes figures
  /// (it turned a stated USD 321.75 into "311.75"), so an ungrounded sentence
  /// is dropped rather than shown. The lead-in runs in a throwaway session
  /// because a session that has been emitting JSON keeps doing so.
  Future<AskCakeReply> _answer(String turn, String data, String route) async {
    var lead = '';
    try {
      final session = await _model.createSession(
          'You are Ask Cake, the assistant inside Cake Wallet. Today is $_today. '
          'Answer the user\'s question in ONE short plain-text sentence using only DATA. '
          'Copy figures and dates exactly as written in DATA and never calculate anything. '
          'The full DATA is shown to the user right below your sentence, so do not repeat lists.',
          permissive: true);
      try {
        lead = (await _model.respond(session, 'DATA:\n$data\n\nQuestion: $turn')).trim();
      } finally {
        await _model.disposeSession(session);
      }
    } on AskCakeModelException {
      lead = '';
    }
    if (!leadInIsGrounded(lead, data) || data.contains(lead) || claimsACause(lead, data)) lead = '';
    final start = lead.isEmpty ? 0 : lead.length + 2;
    return AskCakeReply(lead.isEmpty ? data : '$lead\n\n$data',
        route: route, dataStart: start, dataEnd: start + data.length);
  }

  /// True when [lead] explains why something happened and DATA does not use
  /// that wording: the records list what happened, never the reason, so a
  /// "because" in the summary sentence is the model's guess.
  static bool claimsACause(String lead, String data) {
    final haystack = data.toLowerCase();
    for (final match in RegExp(
            r"\b(because|due to|caused by|as a result|result of|since the|which is why|that is why|that's why|therefore|led to|owing to)\b")
        .allMatches(lead.toLowerCase())) {
      if (!haystack.contains(match.group(0)!)) return true;
    }
    return false;
  }

  /// True when [lead] is a single short sentence whose every number occurs in [data].
  static bool leadInIsGrounded(String lead, String data) {
    if (lead.isEmpty || lead.length > 240 || lead.contains('\n') || lead.contains('{')) return false;
    final haystack = data.replaceAll(',', '');
    for (final match in RegExp(r'\d+(?:\.\d+)?').allMatches(lead.replaceAll(',', ''))) {
      if (!haystack.contains(match.group(0)!)) return false;
    }
    return true;
  }

  Future<AskCakeReply> _addContact(String turn) async {
    // The address is lifted from the user's own text, never generated by the model.
    final address = _actionTurns.reversed.map(addressIn).firstWhere((a) => a != null, orElse: () => null);
    Map<String, dynamic> fields;
    const schema = [
      AskCakeField.string('name', description: 'Name to save the contact under'),
      AskCakeField.string('coin', description: 'Ticker: LTC, BTC, XMR, ETH...'),
    ];
    if (address != null) {
      fields = await _slots('', 'NewContact', schema,
          instructions: 'Extract the contact name and coin ticker from the text.',
          text: _actionTurns.join('. ').replaceAll(address, '[address]'));
    } else {
      fields = await _slots(
          'Fill in the new contact from what the user wrote. Leave out anything they did not give.',
          'NewContact',
          schema);
    }
    var name = _clean(fields['name']);
    // A name the user never typed is not used; the question below asks for it instead.
    bool typed(String? n) => n != null && _actionTurns.join(' ').toLowerCase().contains(n.toLowerCase());
    if (!typed(name) && _label != null) {
      // The router misread the name: ask Apple's model once, on text with the address removed.
      final label = _label;
      _label = null;
      try {
        fields = await _slots('', 'NewContact', schema,
            instructions: 'Extract the contact name and coin ticker from the text.',
            text: _actionTurns.map(askCakeMaskAddresses).join('. '));
      } finally {
        _label = label;
      }
      name = _clean(fields['name']);
    }
    if (!typed(name)) name = null;
    final route = 'add_contact name=${name ?? '-'} coin=${_clean(fields['coin']) ?? '-'}';
    if (name == null) {
      _pendingTool = 'add_contact';
      return AskCakeReply('What name should I save this contact under?', route: route);
    }
    if (address == null) {
      _pendingTool = 'add_contact';
      return AskCakeReply('What is $name\'s address, and which coin is it for?', route: route);
    }
    final result = _tools.addContact(name: name, address: address, coin: _clean(fields['coin']));
    return AskCakeReply(result.text, action: result.action, route: route);
  }

  Future<AskCakeReply> _send(String turn) async {
    const schema = [
      AskCakeField.string('recipient', description: 'Contact name the user wants to pay'),
      AskCakeField.string('amount',
          description: 'Amount as digits, e.g. 0.5. Omit if the user gave no specific amount'),
      AskCakeField.boolean('amountIsDollars', description: 'true if the amount is in dollars'),
    ];
    String? recipient;
    Map<String, dynamic> fields;
    final address = _actionTurns.reversed.map(addressIn).firstWhere((a) => a != null, orElse: () => null);
    if (address != null) {
      fields = await _slots('', 'Payment', schema,
          instructions: 'Extract the payment amount from the text.',
          text: _actionTurns.join('. ').replaceAll(address, '[address]'));
      recipient = address;
    } else {
      fields = await _slots(
          'Fill in the payment from what the user wrote. Leave out anything they did not give.', 'Payment', schema);
      recipient = _clean(fields['recipient']);
      if (recipient == '[address]') recipient = null;
      if (recipient != null && _pronouns.contains(recipient.toLowerCase())) recipient = _lastPerson;
      // A saved contact named in this request wins over the model's reading,
      // which can pick up a name from an earlier, unrelated request.
      recipient = _tools.contactNamedIn(_actionTurns.join(' ')) ?? recipient;
    }
    final amount = _groundedAmount(fields['amount']);
    final route = 'send_payment to=${recipient ?? '-'} amount=${amount ?? '-'}';
    if (recipient == null) {
      _pendingTool = 'send_payment';
      return AskCakeReply('Who would you like to send to? Give me a contact name or an address.',
          route: route);
    }
    if (recipient.length < 26) _lastPerson = recipient;
    if (amount == null) {
      _pendingTool = 'send_payment';
      return AskCakeReply(
          'How much would you like to send to $recipient? You will review and confirm it in Send before anything goes out.',
          route: route);
    }
    final window = _actionTurns.join(' ').toLowerCase();
    final fiat = window.contains(r'$') || window.contains('dollar') || window.contains('usd') ||
        (fields['amountIsDollars'] == true && RegExp(r'buck|fiat|eur|€|£').hasMatch(window));
    final result = _tools.send(recipient: recipient, amount: amount, fiat: fiat);
    return AskCakeReply(result.text, action: result.action, route: route);
  }

  // --- deterministic helpers -------------------------------------------------

  static const _pronouns = {'him', 'her', 'them', 'he', 'she', 'they', 'that person', 'same person'};
  static const _stopWords = {
    'ltc', 'litecoin', 'btc', 'bitcoin', 'xmr', 'monero', 'eth', 'ethereum', //
    'transactions', 'transaction', 'payment', 'payments', 'none', 'null', 'n/a', 'unknown', //
    'last', 'latest', 'recent', 'recently', 'all', 'total', 'incoming', 'outgoing', 'received', //
    'sent', 'my', 'me', 'history', 'everything', 'newest', 'oldest', 'first', 'week', 'month', 'year', //
    'past', 'this', 'that', 'the', 'largest', 'biggest', 'smallest', 'amount', 'amounts', 'ever', 'today', //
    'yesterday', 'ago', 'so', 'far', 'in', 'on', 'of', 'for', 'to', 'from', 'a', 'an',
  };
  static const _months = [
    'january', 'february', 'march', 'april', 'may', 'june', //
    'july', 'august', 'september', 'october', 'november', 'december',
  ];
  static const _numberWords = {
    'half': 0.5, 'quarter': 0.25, 'one': 1.0, 'two': 2.0, 'three': 3.0, 'four': 4.0, 'five': 5.0, 'six': 6.0, //
    'seven': 7.0, 'eight': 8.0, 'nine': 9.0, 'ten': 10.0, 'eleven': 11.0, 'twelve': 12.0, 'fifteen': 15.0, //
    'twenty': 20.0, 'thirty': 30.0, 'forty': 40.0, 'fifty': 50.0, 'hundred': 100.0, 'thousand': 1000.0,
  };

  String? _clean(dynamic value) {
    if (value is! String) return null;
    final text = value.trim();
    const empty = {'none', 'null', 'n/a', 'unknown'};
    return text.isEmpty || empty.contains(text.toLowerCase()) ? null : text;
  }

  /// A model-extracted keyword only counts if the user actually typed it.
  String? _groundedWord(dynamic value, String turn) {
    final text = _clean(value);
    if (text == null) return null;
    // Drop filler words and counts ("last 3") so only a real keyword remains.
    final kept = text
        .split(RegExp(r'\s+'))
        .where((w) =>
            !_stopWords.contains(w.toLowerCase()) &&
            !_months.contains(w.toLowerCase()) &&
            !RegExp(r'^\d+(st|nd|rd|th)?$', caseSensitive: false).hasMatch(w))
        .join(' ');
    if (kept.isEmpty) return null;
    return turn.toLowerCase().contains(kept.toLowerCase()) ? kept : null;
  }

  /// An answer to a follow-up question is short and is not itself a question;
  /// anything else is routed afresh instead of being forced into the pending action.
  bool _looksLikeAnswer(String turn) =>
      !turn.trim().endsWith('?') && turn.trim().split(RegExp(r'\s+')).length <= 6;

  /// Numbers the user typed for the action being prepared. Addresses are
  /// removed first (they are full of digits) and a digit run only counts when
  /// it does not sit inside a longer word.
  List<double> _typedNumbers() {
    var text = _actionTurns.join(' ').toLowerCase();
    for (final turn in _actionTurns) {
      final address = addressIn(turn);
      if (address != null) text = text.replaceAll(address.toLowerCase(), ' ');
    }
    final numbers = RegExp(r'(?<![a-z0-9.])(\d+(?:[.,]\d+)?|\.\d+)')
        .allMatches(text)
        .map((m) => double.tryParse(m.group(1)!.replaceAll(',', '.')))
        .whereType<double>()
        .where((n) => n > 0)
        .toList();
    for (final entry in _numberWords.entries) {
      if (RegExp('\\b${entry.key}\\b').hasMatch(text)) numbers.add(entry.value);
    }
    return numbers;
  }

  /// The amount must be a number the user typed for this action. The model's
  /// reading is used only to choose between several typed numbers; when exactly
  /// one was typed, that one wins whatever the model said.
  double? _groundedAmount(dynamic value) {
    final typed = _typedNumbers().toSet();
    if (typed.isEmpty) return null;
    if (typed.length == 1) return typed.first;
    final proposed = double.tryParse(
        (value ?? '').toString().replaceAll(r'$', '').replaceAll(RegExp(r'[A-Za-z ]'), ''));
    if (proposed == null) return null;
    for (final number in typed) {
      if ((number - proposed).abs() < 1e-9) return number;
    }
    return null;
  }

  static String? addressIn(String text) {
    for (final word in text.split(RegExp(r'[\s,;:]+'))) {
      if (word.length >= 26 && RegExp(r'^[A-Za-z0-9]+$').hasMatch(word) && RegExp(r'\d').hasMatch(word)) {
        return word;
      }
    }
    return null;
  }

  static String? parseDirection(String text) {
    final t = ' ${text.toLowerCase()} ';
    // "send me", "paid me", "from Carol": money coming in, despite the verb.
    final paidMe = RegExp(r'\b(paid|pay|pays|sent|send|sends|gave|give|gives|owes?) me\b|\bfrom (?!me\b|my\b|this\b|the\b)\w').hasMatch(t);
    final incoming = paidMe ||
        ['receive', 'received', 'got ', 'incoming', 'earned', 'income', 'deposit', 'get paid', 'landed', 'came in', 'arrived']
            .any(t.contains);
    final outgoing = !paidMe &&
        ['sent', 'send ', 'paid ', ' pay ', 'payment', 'spent', 'spend', 'outgoing', 'bought'].any(t.contains);
    if (incoming == outgoing) return null;
    return incoming ? 'incoming' : 'outgoing';
  }

  /// Calendar phrases are resolved in code; the model is poor at them.
  static AskCakeRange parseRange(String text, DateTime now) {
    final t = text.toLowerCase();
    final today = DateTime(now.year, now.month, now.day);
    final endOfToday = today.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
    AskCakeRange days(int count, String label) =>
        AskCakeRange(today.subtract(Duration(days: count - 1)), endOfToday, label);

    for (var i = 0; i < _months.length; i++) {
      final name = _months[i];
      final mentioned = name == 'may' ? t.contains(' in may') : RegExp('\\b$name\\b').hasMatch(t);
      if (!mentioned) continue;
      final year = i + 1 <= now.month ? now.year : now.year - 1;
      final start = DateTime(year, i + 1);
      final end = DateTime(year, i + 2).subtract(const Duration(milliseconds: 1));
      return AskCakeRange(start, end.isAfter(endOfToday) ? endOfToday : end,
          '${name[0].toUpperCase()}${name.substring(1)} $year');
    }
    bool has(List<String> phrases) => phrases.any(t.contains);
    if (has(['last month', 'previous month'])) {
      final start = DateTime(now.year, now.month - 1);
      return AskCakeRange(start, DateTime(now.year, now.month).subtract(const Duration(milliseconds: 1)), 'last month');
    }
    if (has(['this month', 'month so far'])) return AskCakeRange(DateTime(now.year, now.month), endOfToday, 'this month');
    if (has(['yesterday'])) {
      return AskCakeRange(today.subtract(const Duration(days: 1)), today.subtract(const Duration(milliseconds: 1)), 'yesterday');
    }
    if (has(['today'])) return AskCakeRange(today, endOfToday, 'today');
    if (has(['this week', 'past week', 'last week', '7 days'])) return days(7, 'the last 7 days');
    if (has(['30 days', 'recent', 'lately'])) return days(30, 'the last 30 days');
    if (has(['90 days', 'three months', '3 months', 'quarter'])) return days(90, 'the last 90 days');
    if (has(['last year'])) {
      return AskCakeRange(DateTime(now.year - 1), DateTime(now.year).subtract(const Duration(milliseconds: 1)), 'last year');
    }
    if (has(['this year', 'year so far'])) return AskCakeRange(DateTime(now.year), endOfToday, 'this year');
    return AskCakeRange.allTime(endOfToday);
  }
}
