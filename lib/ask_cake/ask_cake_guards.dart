import 'dart:convert';

import 'package:flutter/services.dart';

/// One pre-canned reply to a question Ask Cake asks. Buttons are built in code
/// from fixed lists and wallet data, never written by a model.
class AskCakeOption {
  const AskCakeOption(this.label, this.kind, {this.payload});

  final String label;

  /// confirmSetting, openSettings or dismiss
  final String kind;
  final Map<String, dynamic>? payload;
}

/// A clarifying question with its reply buttons. Nothing is prepared or
/// changed until a button is tapped; typing instead is treated as a new message.
class AskCakeQuestion {
  const AskCakeQuestion(this.text, this.options);

  final String text;
  final List<AskCakeOption> options;
}

/// Code-level safety checks around the router. None of them use a model, and
/// they can only make an outcome stricter: turn an action into a refusal or a
/// question, never the reverse.
class AskCakeGuards {
  AskCakeGuards(this._seedWords);

  static Future<AskCakeGuards> load() async => AskCakeGuards(
      (jsonDecode(await rootBundle.loadString('assets/ask_cake/seed_words.json')) as List).cast<String>().toSet());

  final Set<String> _seedWords;

  static const refusals = {
    'seed_or_keys':
        'I can\'t show, read out or copy seed phrases or private keys. You can view them yourself in Settings > Recovery & Keys after authenticating.',
    'destructive':
        'I can\'t delete wallets or erase anything. You can remove a wallet yourself from the Wallets tab; make sure its recovery phrase is backed up first.',
    'investment_advice': 'I can\'t give investment advice, but I can show you prices and your own activity.',
  };

  static const secretInputWarning =
      'That looks like a recovery phrase or private key. I have not kept it, and you should never type one into a chat. '
      'To bring a wallet into Cake Wallet, use Restore from the Wallets tab.';

  static final _rawKey = RegExp(r'(?<![0-9a-fA-F])[0-9a-fA-F]{64}(?![0-9a-fA-F])');
  static final _wif = RegExp(r'(?<![1-9A-HJ-NP-Za-km-z])[5KL][1-9A-HJ-NP-Za-km-z]{50,51}(?![1-9A-HJ-NP-Za-km-z])');
  static final _extendedKey = RegExp(r'\b[xyzYZ]prv[1-9A-HJ-NP-Za-km-z]{100,}');

  /// True when the message looks like a pasted recovery phrase or private key.
  /// Such a message must not reach a model, the history or the logs.
  bool secretInput(String text) {
    var run = 0;
    for (final match in RegExp(r'[a-z]+').allMatches(text.toLowerCase())) {
      run = _seedWords.contains(match.group(0)) ? run + 1 : 0;
      if (run >= 11) return true;
    }
    return _rawKey.hasMatch(text) || _wif.hasMatch(text) || _extendedKey.hasMatch(text);
  }

  /// Capabilities that prepare, change or open something, plus the catch-alls a
  /// missed secret or delete request tends to land on.
  static const _acting = {
    'add_contact', 'send_payment', 'receive', 'swap', 'buy', 'sell', 'move_funds', 'sign_message', //
    'change_setting', 'switch_wallet', 'set_lightning_username', 'rescan', //
    'general_question', 'wallet_overview', 'app_status', 'manage_wallets',
  };

  static final _howTo = RegExp(
      r"^\s*(how|where|why|what happens|what's involved|what is|what are|is it|is there|can i|should i|do i|does|would|will)\b",
      caseSensitive: false);
  static final _secretNoun = RegExp(
      r'(seed|mnemonic|recovery (phrase|words?)|backup (phrase|words)|secret (words|phrase|key)|private key|spend key|view key|xpub|\b(12|24|25) words\b|keys\b)');
  static final _secretVerb = RegExp(
      r"(show|display|print|read|recite|spell|tell|give|reveal|see|copy|paste|export|dump|send|text|email|airdrop|message|put|save|store|write|remind|what'?s|what is|what are)");
  static final _restoring = RegExp(r'\b(restore|import|bring|have my|coming from)\b');
  static final _destroy = RegExp(
      r'(delete|remove|erase|wipe|nuke|purge|destroy|trash|bin|burn|scrub|forget|uninstall|get rid of|take .{0,25} off|make .{0,25} disappear|factory reset|clean slate|start over|start fresh|reset (the|this|my) (app|phone|wallet)|gone\b)');
  static final _destroyObject = RegExp(r'(wallet|wallets|app|everything|all of (it|them)|it all|data|phone|device|clean)');
  static final _harmlessObject = RegExp(r'\b(contact|address book|note|label|dapp|session|node)\b');

  /// True for "how do I", "what is", "can I", "does it" style wording: a question about the app, not an order.
  /// "how do I", "where is", "why": asking how something works, never asking for the user's own data.
  static bool isHowTo(String text) => RegExp(r'^\s*(how|where|why)\b').hasMatch(text.toLowerCase());

  /// A question about what Cake Wallet offers ("which providers do you support"), not about the user's own data.
  static bool isAboutTheApp(String text) =>
      isQuestion(text) &&
      RegExp(r"\b(do you|does (cake|it|the app|this app)|cake wallet) (support|offer|have|work with|accept)|\b(is|are) .{0,40}\b(supported|available)\b")
          .hasMatch(text.toLowerCase());

  /// The user asking about their own past activity ("how much did I spend on...").
  static bool isAboutMyActivity(String text) =>
      RegExp(r"\b(did i|have i|i've|i (spent|paid|sent|received|got|bought|blew)|(was|were) there (a|an|any)\b)")
          .hasMatch(text.toLowerCase());

  /// "Do I have a Monero wallet?", "have I got a bitcoin wallet".
  static bool isAboutMyWallets(String text) =>
      RegExp(r"\b(do i (have|own)|have i got)\b.{0,30}\bwallets?\b|\b(which|what|how many) wallets? (do|have) i\b|\bmy wallets\b")
          .hasMatch(text.toLowerCase()) &&
      !isHowTo(text);

  /// Worry about the network seeing where the user connects from (ISP, IP address, being tracked).
  static bool isAboutConnectionPrivacy(String text) => RegExp(
          r"\b(isp|ip address|my ip|connecting from|where i('m| am) connect\w*|network (traffic|activity)|snoop\w*|"
          r"track(s|ing)? (me|my)|my (traffic|connection)|vpn)\b")
      .hasMatch(text.toLowerCase().replaceAll('’', "'"));

  /// A request for a recap of a period ("quick recap of the past 90 days").
  static bool isRecapRequest(String text) =>
      RegExp(r'\b(recap|summary|summari[sz]e|rundown|overview)\b').hasMatch(text.toLowerCase()) &&
      RegExp(r'\b(past|last|this|today|yesterday|week|month|year|days?)\b').hasMatch(text.toLowerCase());

  /// Fees the user has already paid ("what have network fees cost me this year"), as opposed to the current fee level.
  static bool isAboutFeesPaid(String text) =>
      RegExp(r"\b(cost me|costing me|have i paid|did i pay|i paid|i('ve| have) (paid|spent)|spent on fees|paid in fees|so far)\b")
          .hasMatch(text.toLowerCase().replaceAll('’', "'"));

  /// The user's own wallet failing to sync or connect (not a general question about syncing).
  static bool isAboutMySync(String text) {
    final t = text.toLowerCase().replaceAll('’', "'");
    return RegExp(r"\b(sync\w*|connect\w*|offline|blocks remaining)\b").hasMatch(t) &&
        RegExp(r"\b(my|it|its|it's|wallet|still|stuck)\b").hasMatch(t) &&
        isProblem(t) &&
        !RegExp(r'^(how do|how can|how to|how long)').hasMatch(t);
  }

  /// The user reporting that something of theirs looks wrong or is missing.
  static bool isProblem(String text) => RegExp(
          r"\b(stuck|pending|never|missing|failed|fail|wrong|refund(ed)?|lost|gone|disappeared|error|problem|issue|"
          r"what happened|where('s| is| are| did)|why|still|zero|empty|not (arriv|receiv|show|sync|connect|work|updat|there)\w*|"
          r"(has|have|did|is|was|does|do|wo|ca)n'?t|hasn't|haven't|didn't|isn't|doesn't|won't|can't)\b")
      .hasMatch(text.toLowerCase().replaceAll('’', "'"));

  /// "Open the scanner", "scan this QR": the camera scanner, not a wallet rescan or Silent Payments scanning.
  static bool isScanRequest(String text) {
    final t = text.toLowerCase().trim();
    if (isQuestion(t) || RegExp(r'\b(rescan|silent|blockchain|wallet scan|scanning)\b').hasMatch(t)) return false;
    return RegExp(r'\bscanner\b|^(please )?scan( (it|this|that|one|something))?[.!]?$|'
            r'\bscan\b.{0,30}\b(qr|code|barcode|invoice|address|payment|request)\b|\b(qr|code)\b.{0,20}\bscan\b')
        .hasMatch(t);
  }

  /// "When do I transact most", "what day am I most active": a question about habits, not one transaction.
  static bool isAboutMyHabits(String text) {
    final t = text.toLowerCase().replaceAll('’', "'");
    return RegExp(r"\b(i|my|me|i'm|am i)\b").hasMatch(t) &&
        RegExp(r'\b(when|what time|time of day|times?|days?|weekdays?|months?|hours?|how often|how frequently|busiest|patterns?|habits?)\b')
            .hasMatch(t) &&
        RegExp(r'\b(most|mostly|usually|typically|normally|generally|tend|often|frequently|busiest|patterns?|habits?|most active)\b')
            .hasMatch(t) &&
        RegExp(r'\b(transact\w*|send|spend|receive|pay|use|using|active|activity|busiest|buy|swap|move)\b').hasMatch(t);
  }

  /// A problem the user may need a person for, or a plain request to reach support.
  static bool mayNeedSupport(String text) {
    final t = text.toLowerCase().replaceAll('’', "'");
    if (RegExp(r'\b(support|customer service|help ?desk|a human|real person|an agent|open a ticket|file a ticket)\b').hasMatch(t)) {
      return true;
    }
    return isProblem(t) &&
        RegExp(r'\b(swap\w*|trade|exchange\w*|transaction|tx|payment|funds|money|coins?|balance|refund\w*|deposit|'
                r'withdraw\w*|purchase|order|gift ?card|cake ?pay|sent|received)\b')
            .hasMatch(t);
  }

  static const _coinNames = {
    'bitcoin cash': 'BCH', 'bitcoin': 'BTC', 'btc': 'BTC', 'monero': 'XMR', 'xmr': 'XMR', 'litecoin': 'LTC', //
    'ltc': 'LTC', 'ethereum': 'ETH', 'ether': 'ETH', 'eth': 'ETH', 'tether': 'USDT', 'usdt': 'USDT', //
    'usdc': 'USDC', 'dai': 'DAI', 'solana': 'SOL', 'sol': 'SOL', 'tron': 'TRX', 'trx': 'TRX', //
    'dogecoin': 'DOGE', 'doge': 'DOGE', 'bch': 'BCH', 'zcash': 'ZEC', 'zec': 'ZEC', 'nano': 'XNO', //
    'xno': 'XNO', 'decred': 'DCR', 'dcr': 'DCR', 'wownero': 'WOW', 'bnb': 'BNB', 'ada': 'ADA', //
    'cardano': 'ADA', 'xrp': 'XRP', 'ripple': 'XRP', 'pol': 'POL', 'matic': 'POL',
  };

  /// A direct order to swap ("swap to USDT", "convert my monero into bitcoin"),
  /// with whichever coins it names. Null when the message is not such an order.
  static ({String? from, String? to})? swapOrder(String text) {
    final t = text.toLowerCase().trim();
    if (!RegExp(r"^(please |can you |could you |i want to |i'd like to |i would like to |let'?s |help me )?(swap|exchange|convert|trade)\b")
            .hasMatch(t) ||
        RegExp(r'\b(history|swaps|stuck|failed|status|id)\b').hasMatch(t)) {
      return null;
    }
    String? from;
    String? to;
    final names = _coinNames.keys.map(RegExp.escape).join('|');
    for (final match in RegExp('(\\b(?:to|into|for)\\s+(?:some\\s+)?)?\\b($names)\\b').allMatches(t)) {
      final ticker = _coinNames[match.group(2)!]!;
      if (match.group(1) != null) {
        to ??= ticker;
      } else {
        from ??= ticker;
      }
    }
    if (from == to) from = null;
    return (from: from, to: to);
  }

  static bool isQuestion(String text) {
    final t = text.toLowerCase().trim();
    // "can you send...", "could u turn on..." are orders phrased politely, not questions about the app.
    if (RegExp(r'^(can|could|will|would) (you|u|ya|we)\b').hasMatch(t)) return false;
    return RegExp(r'^(how|where|why|what|which|when|who|is|are|can|could|does|do|should|will|would)\b').hasMatch(t);
  }

  /// The capability to use: the router's choice, or a refusal when the wording demands one.
  static String backstop(String text, String tool) {
    final t = text.toLowerCase();
    if (!_acting.contains(tool) || _howTo.hasMatch(t)) return tool;
    if (_secretNoun.hasMatch(t) && _secretVerb.hasMatch(t) && !_restoring.hasMatch(t)) return 'seed_or_keys';
    if (_destroy.hasMatch(t) && _destroyObject.hasMatch(t) && !_harmlessObject.hasMatch(t)) return 'destructive';
    return tool;
  }

  static const _fiatCodes =
      'usd|eur|gbp|jpy|cad|aud|chf|cny|inr|brl|mxn|sek|nok|pln|try|krw|zar|ars|ngn|czk|dkk|hkd|sgd|nzd|thb|php|idr|rub|uah|ils|aed';
  static const _languages =
      'english|spanish|german|french|italian|portuguese|dutch|polish|russian|ukrainian|turkish|japanese|chinese|korean|arabic|hindi|thai|vietnamese|indonesian|czech|croatian|bulgarian|armenian|hausa|yoruba|burmese|tagalog|urdu|espa[nñ]ol|deutsch|fran[cç]ais';

  /// Words that show the user actually named a setting.
  static final settingWords = <String, RegExp>{
    'tor': RegExp(r'\btor\b|onion'),
    'fiat_currency': RegExp(
        'currenc|fiat|dollar|euro|pound|sterling|peso|rupee|franc|yen|yuan|real\\b|krona|kroner|won\\b|lira|zloty|baht|rand\\b|\\b($_fiatCodes)\\b'),
    'language': RegExp('language|translat|\\b($_languages)\\b'),
    'theme': RegExp(r'theme|dark|light|night|bright|black|white|appearance|colou?rs?\b'),
    'hide_balance': RegExp(
        r'balance|hide|hidden|conceal|visible|amounts?\b|totals?\b|figures|numbers|mask|blur|private mode|incognito|how much i (have|own|hold)'),
    'bitcoin_unit': RegExp(r'\bsats?\b|satoshi|\bbtc\b|unit|denomin|decimal'),
    'show_charts_tab': RegExp(r'chart|graph|market'),
    'show_apps_tab': RegExp(r'\bapps?\b|dapp'),
    'show_buy_sell': RegExp(r'\bbuy|\bsell|purchas'),
    'fee_priority': RegExp(r'\bfees?\b|priority|slow|fast|cheap|economy|speed|urgent|quick'),
    'fiat_api': RegExp(r'fiat|price|rates?\b|api|quotes?\b|valuation'),
    'swap_api': RegExp(r'swap|exchange|trade|trading'),
    'payjoin': RegExp(r'pay ?join'),
    'auto_generate_addresses': RegExp(r'address|subaddress|rotat|reus'),
    'mweb': RegExp(r'mweb|mimblewimble|extension block'),
    'silent_payments_scanning': RegExp(r'silent|scan'),
    'prevent_screenshots': RegExp(r'screen ?shots?|screen[- ]?(record|captur|grab)|captur|recording'),
    'background_sync': RegExp(r'background|sync'),
    'notifications': RegExp(r'notif|alerts?\b|push|pings?\b|buzz'),
    'save_recipient_address': RegExp(r'recipient|payee|remember|save|sav(ed|ing)|stor(e|ing)'),
    'address_lookups': RegExp(r'look ?ups?|resolv|\bens\b|openalias|unstoppable|handles?\b|domains?\b|usernames?\b|names?\b'),
    'block_explorer_apis': RegExp(r'explorer|block'),
    'lightning': RegExp(r'lightning|\bln\b'),
  };

  static const settingNames = {
    'tor': 'Tor',
    'fiat_currency': 'display currency',
    'language': 'app language',
    'theme': 'theme',
    'hide_balance': 'hide balance',
    'bitcoin_unit': 'Bitcoin unit',
    'show_charts_tab': 'Charts tab',
    'show_apps_tab': 'Apps tab',
    'show_buy_sell': 'Buy and Sell buttons',
    'fee_priority': 'default fee level',
    'fiat_api': 'price data',
    'swap_api': 'swap providers connection',
    'payjoin': 'PayJoin',
    'auto_generate_addresses': 'new address for every payment',
    'mweb': 'MWEB',
    'silent_payments_scanning': 'Silent Payments scanning',
    'prevent_screenshots': 'screenshot protection',
    'background_sync': 'background sync',
    'notifications': 'notifications',
    'save_recipient_address': 'saving recipient addresses',
    'address_lookups': 'address lookups',
    'block_explorer_apis': 'block explorer connection',
    'lightning': 'Lightning',
  };

  static final _security =
      RegExp(r'\bpin\b|pass ?code|finger ?print|face ?id|touch ?id|biometr|\b2fa\b|two[- ]factor|authenticator|duress');

  static String describeSetting(String setting, Object? value) {
    final v = '$value'.toLowerCase();
    final name = settingNames[setting] ?? setting;
    if (const {'on', 'true', 'enable', 'enabled', 'yes'}.contains(v)) return 'turn $name on';
    if (const {'off', 'false', 'disable', 'disabled', 'no'}.contains(v)) return 'turn $name off';
    return 'set $name to $value';
  }

  /// A change_setting label is accepted as-is only when the user's own words
  /// name that setting (or its value). PIN, biometrics and 2FA wording goes to
  /// security settings. Otherwise the app asks before preparing anything.
  ///
  /// Returns the label to act on, or null with [question] set.
  ///
  /// [latest] is the newest message on its own. When it names exactly one
  /// setting, that setting wins over the router's choice: earlier messages must
  /// not drag a new request onto the setting they were about.
  static ({Map<String, dynamic>? label, AskCakeQuestion? question}) groundSetting(
      String recentText, Map<String, dynamic> label,
      {String? latest}) {
    if (label['tool'] != 'change_setting') return (label: label, question: null);
    var t = recentText.toLowerCase();
    if (latest != null) {
      final now = latest.toLowerCase();
      final named = [
        for (final entry in settingWords.entries)
          if (entry.value.hasMatch(now)) entry.key
      ];
      if (named.isNotEmpty) t = now;
      if (named.length == 1 && named.single != label['setting']) label = {...label, 'setting': named.single};
    }
    final setting = label['setting'];
    final value = '${label['value'] ?? ''}'.toLowerCase();
    final words = setting is String ? settingWords[setting] : null;
    if (_security.hasMatch(t) && !(words != null && words.hasMatch(t))) {
      return (label: {'tool': 'security_settings'}, question: null);
    }
    if (words == null || value.isEmpty) {
      return (
        label: null,
        question: const AskCakeQuestion('I\'m not sure which setting you mean.', [
          AskCakeOption('Open Settings', 'openSettings'),
          AskCakeOption('Ask another way', 'dismiss'),
        ])
      );
    }
    final valueNamed =
        value.length >= 3 && !const {'on', 'off', 'true', 'false'}.contains(value) && t.contains(value);
    if (words.hasMatch(t) || valueNamed) return (label: label, question: null);
    final description = describeSetting(setting as String, label['value']);
    return (
      label: null,
      question: AskCakeQuestion('Did you mean: $description?', [
        AskCakeOption('Yes, $description', 'confirmSetting', payload: label),
        const AskCakeOption('No, something else', 'dismiss'),
        const AskCakeOption('Open Settings', 'openSettings'),
      ])
    );
  }

  static const _numbers = {
    'a': 1, 'an': 1, 'one': 1, 'two': 2, 'couple': 2, 'three': 3, 'few': 3, 'four': 4, 'five': 5, 'six': 6, //
    'seven': 7, 'eight': 8, 'nine': 9, 'ten': 10, 'twelve': 12, 'eighteen': 18, 'twenty': 20, 'thirty': 30, //
    'sixty': 60, 'ninety': 90,
  };
  static const _unitDays = {'day': 1, 'week': 7, 'fortnight': 14, 'month': 30, 'quarter': 91, 'year': 365};
  static final _duration = RegExp(
      '\\b(\\d+|${_numbers.keys.join('|')})\\s+(?:of\\s+)?(day|week|fortnight|month|quarter|year)s?\\b');
  static final _shortDuration = RegExp(r'\b(\d+)\s?(d|w|m|y)\b');

  /// Price data and swap connections have three modes, and the small router
  /// tends to flatten them to on/off. When the message names a mode in words,
  /// those words decide; otherwise the router's reading stands.
  static String connectionMode(String message, String proposed) {
    final text = message.toLowerCase();
    if (RegExp(r'clearnet|clear net|without tor|no tor|not (over|through|via) tor|directly|normal(ly)? (connection|internet)')
        .hasMatch(text)) {
      return 'on';
    }
    if (RegExp(r'\b(over|through|via|using|only)\s+tor\b|\btor[- ]only\b|\bonion\b').hasMatch(text)) return 'tor only';
    return proposed;
  }

  /// "Block screenshots" turns the protection on and "allow screenshots" turns
  /// it off; the small router sometimes reads the verb as the switch position.
  static String screenshotProtection(String message, String proposed) {
    final text = message.toLowerCase();
    const target = r"\W+(?:\w+\W+){0,3}?(screenshots?|screen ?(shots?|captures?|recording))";
    if (RegExp('(block|prevent|stop|disable|disallow|forbid|no)$target').hasMatch(text)) return 'on';
    if (RegExp('(allow|permit|enable|let me (take|make))$target').hasMatch(text)) return 'off';
    return proposed;
  }

  static bool mentionsPeriod(String message) => RegExp(
          r'today|yesterday|24 ?h|\bdays?\b|week|month|year|quarter|all[- ]time|\bever\b|history|since|lately|recent|over time|\b\d+ ?[dwmy]\b|trend|done|doing|moved|changed?|performance')
      .hasMatch(message.toLowerCase());

  /// An explicit duration in the latest message ("four weeks", "90 days")
  /// decides the price range; otherwise the router's reading stands.
  static String? priceRange(String message, String? proposed) {
    final t = message.toLowerCase();
    final match = _duration.firstMatch(t) ?? _shortDuration.firstMatch(t);
    if (match == null) return proposed;
    final count = int.tryParse(match.group(1)!) ?? _numbers[match.group(1)!]!;
    final unit = _unitDays[match.group(2)!] ?? const {'d': 1, 'w': 7, 'm': 30, 'y': 365}[match.group(2)!]!;
    final days = count * unit;
    if (days <= 1) return '1d';
    if (days <= 10) return '7d';
    if (days <= 45) return '30d';
    if (days <= 400) return '1y';
    return 'all';
  }
}
