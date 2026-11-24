import 'package:cake_wallet/entities/contact.dart';
import 'package:cake_wallet/entities/transaction_description.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cake_wallet/wownero/wownero.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/store/dashboard/fiat_conversion_store.dart';
import 'package:cw_core/cake_hive.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';

/// True when every word of [search] occurs in [note], ignoring case and a
/// trailing plural "s" ("freelance invoices" matches "Freelance invoice 114").
bool askCakeNoteMatches(String note, String search) {
  String norm(String w) => w.length > 3 && w.endsWith('s') ? w.substring(0, w.length - 1) : w;
  final words = RegExp(r'[a-z0-9]+').allMatches(note.toLowerCase()).map((m) => norm(m.group(0)!)).toSet();
  final wanted = RegExp(r'[a-z0-9]+').allMatches(search.toLowerCase()).map((m) => norm(m.group(0)!));
  return wanted.isNotEmpty && wanted.every(words.contains);
}

/// A calendar window resolved in code from the user's wording.
class AskCakeRange {
  const AskCakeRange(this.start, this.end, this.label);

  factory AskCakeRange.allTime(DateTime now) => AskCakeRange(DateTime(2009), now, 'all time');

  final DateTime start;
  final DateTime end;
  final String label;

  bool contains(DateTime date) => !date.isBefore(start) && !date.isAfter(end);

  String get describe => label == 'all time' ? 'all time' : '$label (${_d(start)} to ${_d(end)})';
}

String _d(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _n(double v, [int digits = 8]) {
  var s = v.toStringAsFixed(digits);
  if (s.contains('.')) s = s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  return s;
}

/// When a set of transactions happened: busiest weekday, part of the day and
/// month, counted in code from their dates (the phone's own time zone).
String askCakePatterns(List<DateTime> dates, AskCakeRange range) {
  if (dates.isEmpty) return 'No transactions for ${range.describe}.';
  const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
  const parts = ['Night (midnight to 6am)', 'Morning (6am to noon)', 'Afternoon (noon to 6pm)', 'Evening (6pm to midnight)'];
  String times(int n) => '$n ${n == 1 ? 'transaction' : 'transactions'}';
  MapEntry<K, int> top<K>(Iterable<K> keys) {
    final counts = <K, int>{};
    for (final key in keys) {
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts.entries.reduce((a, b) => b.value > a.value ? b : a);
  }

  final sorted = [...dates]..sort();
  final day = top(sorted.map((d) => d.weekday));
  final part = top(sorted.map((d) => d.hour ~/ 6));
  final month = top(sorted.map((d) => d.year * 12 + d.month - 1));
  final span = (sorted.last.year - sorted.first.year) * 12 + sorted.last.month - sorted.first.month + 1;
  return [
    'When you use this wallet, ${range.describe} (${times(sorted.length)}):',
    '- Busiest day of the week: ${days[day.key - 1]} (${times(day.value)})',
    '- Busiest time of day: ${parts[part.key]} (${times(part.value)})',
    '- Busiest month: ${months[month.key % 12]} ${month.key ~/ 12} (${times(month.value)})',
    if (span >= 2)
      sorted.length >= span
          ? '- Average: ${_n(sorted.length / span, 1)} a month'
          : '- Average: ${_n(sorted.length * 12 / span, 1)} a year',
    '- First transaction: ${_d(sorted.first)}',
    '- Most recent: ${_d(sorted.last)}',
  ].join('\n');
}

/// Something the user must confirm in the regular Cake Wallet UI. Ask Cake
/// never signs, broadcasts or writes on its own; it only prepares these.
sealed class AskCakeAction {
  const AskCakeAction(this.buttonLabel);

  final String buttonLabel;
}

class AskCakeSendAction extends AskCakeAction {
  const AskCakeSendAction({required this.address, required this.amount, required this.scheme})
      : super('Review in Send');

  final String address;
  final String amount;
  final String scheme;
}

class AskCakeAddContactAction extends AskCakeAction {
  const AskCakeAddContactAction({required this.name, required this.address, required this.currency})
      : super('Review contact');

  final String name;
  final String address;
  final CryptoCurrency currency;
}

class AskCakeReceiveAction extends AskCakeAction {
  const AskCakeReceiveAction({this.lightning = false, this.addressType}) : super('Open Receive');

  final bool lightning;

  /// One of the router's address types (taproot, segwit, legacy, silent_payments, mweb, shielded, transparent), if asked for.
  final String? addressType;
}

/// A reversible setting change the user confirms with one tap in the chat.
class AskCakeApplySettingAction extends AskCakeAction {
  const AskCakeApplySettingAction({required this.setting, required this.value, required String label}) : super(label);

  final String setting;
  final String value;
}

/// Opens an existing screen by route name and changes nothing. With [auth] the
/// app's own PIN / 2FA prompt comes first.
class AskCakeOpenRouteAction extends AskCakeAction {
  const AskCakeOpenRouteAction(this.route, String label, {this.arguments, this.auth = false}) : super(label);

  final String route;
  final Object? arguments;
  final bool auth;
}

/// Opens one of the screens that are built as pages rather than routes.
class AskCakeOpenPageAction extends AskCakeAction {
  const AskCakeOpenPageAction(this.page, String label, {this.from, this.to, this.asset}) : super(label);

  /// swap, buy, sell, cakePay, settings, lightningDeposit, lightningWithdrawal, exportTransactions
  final String page;
  final String? from;
  final String? to;
  final String? asset;
}

/// Switches to another wallet on this device after the app's usual unlock prompt.
class AskCakeSwitchWalletAction extends AskCakeAction {
  const AskCakeSwitchWalletAction(this.name) : super('Switch wallet');

  final String name;
}

/// Opens the in-app support chat. Nothing is sent to support until the user writes there.
class AskCakeSupportAction extends AskCakeAction {
  const AskCakeSupportAction() : super('Chat with support');
}

/// Switches to another account inside the open wallet (Monero and Wownero).
class AskCakeSwitchAccountAction extends AskCakeAction {
  const AskCakeSwitchAccountAction(this.id, this.name) : super('Switch to $name');

  final int id;
  final String name;
}

/// One account inside the open wallet.
class AskCakeAccount {
  const AskCakeAccount(this.id, this.name, this.balance, {required this.current});

  final int id;
  final String name;

  /// As the wallet reports it, without the ticker; null when unknown.
  final String? balance;
  final bool current;
}

/// The accounts of [wallet]; empty for wallet types that have none.
List<AskCakeAccount> askCakeAccounts(WalletBase? wallet) {
  if (wallet == null) return const [];
  try {
    if (wallet.type == WalletType.monero) {
      final current = monero!.getCurrentAccount(wallet).id;
      return [
        for (final a in monero!.getAccountList(wallet).getAll(wallet))
          AskCakeAccount(a.id, a.label, a.balance, current: a.id == current)
      ];
    }
    if (wallet.type == WalletType.wownero) {
      final current = wownero!.getCurrentAccount(wallet).id;
      return [
        for (final a in wownero!.getAccountList(wallet).getAll(wallet))
          AskCakeAccount(a.id, a.label, a.balance, current: a.id == current)
      ];
    }
  } catch (_) {}
  return const [];
}

class AskCakeToolResult {
  const AskCakeToolResult(this.text, {this.action});

  final String text;
  final AskCakeAction? action;
}

/// What the engine needs from a wallet. The app uses [AskCakeTools] (the open
/// wallet); the on-device self-test uses a fixed fixture wallet instead.
abstract class AskCakeToolbox {
  String get coin;

  DateTime get now;

  Future<String> walletOverview();

  String activitySummary(AskCakeRange range);

  /// When the user transacts: busiest weekday, time of day and month.
  String activityPatterns(AskCakeRange range);

  String transactions(AskCakeRange range, {String? direction, String? search, int? limit});

  Future<String> swaps(AskCakeRange range);

  String contacts(String? query);

  String? contactNamedIn(String text);

  AskCakeToolResult addContact({required String name, required String address, String? coin});

  AskCakeToolResult send({required String recipient, required double amount, required bool fiat});

  AskCakeToolResult receive();
}

/// Read-only views over the open wallet, phrased as compact text the model can
/// quote from. Every sum is computed here: the model never does arithmetic.
class AskCakeTools implements AskCakeToolbox {
  AskCakeTools(this._appStore, this._fiatConversionStore, {DateTime Function()? now})
      : _now = now ?? DateTime.now;

  final AppStore _appStore;
  final FiatConversionStore _fiatConversionStore;
  final DateTime Function() _now;


  /// DEMO ONLY: set by the debug "seed demo data" button so the Send hand-off
  /// can be exercised on an empty test wallet. Never set in release builds.
  static bool demoIgnoreBalance = false;

  bool get hasWallet => _appStore.wallet != null;

  @override
  String get coin => _appStore.wallet?.currency.title ?? '';

  double? get _price {
    final wallet = _appStore.wallet;
    return wallet == null ? null : _fiatConversionStore.prices[wallet.currency];
  }

  String get _fiat => _appStore.settingsStore.fiatCurrency.title;

  String _withFiat(double amount) {
    final price = _price;
    final crypto = '${_n(amount)} $coin';
    if (price == null || price == 0) return crypto;
    return '$crypto ($_fiat ${(amount * price).toStringAsFixed(2)})';
  }

  double _available() {
    final wallet = _appStore.wallet;
    if (wallet == null) return 0;
    final balance = wallet.balance[wallet.currency];
    return balance == null ? 0 : double.tryParse(balance.available.toString()) ?? 0;
  }

  @override
  Future<String> walletOverview() async {
    final wallet = _appStore.wallet;
    if (wallet == null) return 'No wallet is open.';
    final balance = wallet.balance[wallet.currency];
    final pending = balance == null ? 0.0 : double.tryParse(balance.unavailable.toString()) ?? 0.0;
    final others = (await WalletInfo.getAll())
        .where((info) => info.id != wallet.id)
        .map((info) => '${info.name} (${walletTypeToDisplayName(info.type)})')
        .toList();
    final price = _price;
    final accounts = askCakeAccounts(wallet);
    final account = accounts.where((a) => a.current).firstOrNull;
    final otherAccounts = accounts.where((a) => !a.current).toList();
    // One fact per line, so the chat can lay them out as a card.
    return [
      'Current wallet: ${wallet.name} (${walletTypeToDisplayName(wallet.type)}, $coin)',
      if (account != null && accounts.length > 1) 'Open account: ${account.name}',
      'Available balance: ${_withFiat(_available())}',
      if (pending > 0) 'Pending or unconfirmed: ${_withFiat(pending)}',
      if (price != null && price > 0) '$coin price: $_fiat ${price.toStringAsFixed(2)}',
      if (price == null || price == 0) 'Fiat price: not available right now',
      if (otherAccounts.isNotEmpty)
        'Other accounts in this wallet: ${otherAccounts.map((a) => a.balance == null ? a.name : '${a.name} (${a.balance} $coin)').join(', ')}',
      others.isEmpty
          ? 'Other wallets: none on this device'
          : 'Other wallets (open one to see its balance): ${others.join(', ')}',
    ].join('\n');
  }

  Map<String, String> _notes() {
    final notes = <String, String>{};
    try {
      for (final description
          in CakeHive.box<TransactionDescription>(TransactionDescription.boxName).values) {
        if (description.note.isEmpty) continue;
        notes[description.id.split('_').first] = description.note;
      }
    } catch (_) {}
    return notes;
  }

  List<_Tx> _transactions(AskCakeRange range) {
    final wallet = _appStore.wallet;
    if (wallet == null) return [];
    final notes = _notes();
    final all = (wallet.transactionHistory.transactions.values as Iterable).cast<TransactionInfo>();
    final list = all
        .where((tx) => range.contains(tx.date))
        .map((tx) => _Tx(
              date: tx.date,
              incoming: tx.direction == TransactionDirection.incoming,
              amount: (double.tryParse(tx.amount.toString()) ?? 0).abs(),
              fee: tx.fee == null ? 0 : (double.tryParse(tx.fee.toString()) ?? 0).abs(),
              note: notes[tx.txHash] ?? notes[tx.id] ?? '',
              pending: tx.isPending,
            ))
        .toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  @override
  String activitySummary(AskCakeRange range) {
    final txs = _transactions(range);
    if (txs.isEmpty) return 'No transactions for ${range.describe}.';
    final sent = txs.where((t) => !t.incoming).toList();
    final received = txs.where((t) => t.incoming).toList();
    final totalSent = sent.fold<double>(0, (sum, t) => sum + t.amount);
    final totalReceived = received.fold<double>(0, (sum, t) => sum + t.amount);
    final fees = sent.fold<double>(0, (sum, t) => sum + t.fee);
    final net = totalReceived - totalSent - fees;
    String describe(_Tx t) =>
        '${_n(t.amount)} $coin on ${_d(t.date)}${t.note.isEmpty ? '' : ' (${t.note})'}';
    return [
      'Summary for ${range.describe}:',
      '- Sent (spent): ${_withFiat(totalSent)} in ${sent.length} transactions',
      '- Received: ${_withFiat(totalReceived)} in ${received.length} transactions',
      '- Network fees paid: ${_withFiat(fees)}',
      '- Net change: ${net >= 0 ? '+' : '-'}${_withFiat(net.abs())} (${net >= 0 ? 'saved more than spent' : 'spent more than received'})',
      if (sent.isNotEmpty)
        '- Largest outgoing (sent): ${describe(sent.reduce((a, b) => a.amount >= b.amount ? a : b))}',
      if (received.isNotEmpty)
        '- Largest incoming (received): ${describe(received.reduce((a, b) => a.amount >= b.amount ? a : b))}',
    ].join('\n');
  }

  @override
  String activityPatterns(AskCakeRange range) =>
      askCakePatterns([for (final t in _transactions(range)) t.date], range);

  @override
  String transactions(AskCakeRange range, {String? direction, String? search, int? limit}) {
    var txs = _transactions(range);
    if (direction == 'incoming') txs = txs.where((t) => t.incoming).toList();
    if (direction == 'outgoing') txs = txs.where((t) => !t.incoming).toList();
    if (search != null && search.isNotEmpty) {
      txs = txs.where((t) => askCakeNoteMatches(t.note, search)).toList();
    }
    final what = [
      if (direction == 'incoming' || direction == 'outgoing') direction!,
      'transactions',
      if (search != null && search.isNotEmpty) 'with a note matching "$search"',
    ].join(' ');
    if (txs.isEmpty) return 'No $what for ${range.describe}.';
    final totalSent = txs.where((t) => !t.incoming).fold<double>(0, (sum, t) => sum + t.amount);
    final totalReceived = txs.where((t) => t.incoming).fold<double>(0, (sum, t) => sum + t.amount);
    final shown = txs.take((limit ?? 10).clamp(1, 20)).toList();
    return [
      '${txs.length} $what for ${range.describe}'
          '${shown.length < txs.length ? ', showing the newest ${shown.length}:' : ', newest first:'}',
      if (direction != 'incoming') 'Total sent: ${_withFiat(totalSent)}',
      if (direction != 'outgoing') 'Total received: ${_withFiat(totalReceived)}',
      for (final t in shown)
        '- ${_d(t.date)} ${t.incoming ? 'received' : 'sent'} ${_withFiat(t.amount)}'
            '${t.fee > 0 ? ', fee ${_n(t.fee)} $coin' : ''}'
            '${t.pending ? ', pending' : ''}'
            '${t.note.isEmpty ? '' : ', note: ${t.note}'}',
    ].join('\n');
  }

  @override
  Future<String> swaps(AskCakeRange range) async {
    final trades = (await Trade.getAll())
        .where((trade) => trade.createdAt != null && range.contains(trade.createdAt!))
        .toList();
    if (trades.isEmpty) return 'No swaps for ${range.describe}.';
    const doneStates = {'complete', 'completed', 'finished', 'traded', 'settled', 'success'};
    const failedStates = {'failed', 'expired', 'refunded', 'refund', 'timed_out', 'overdue'};
    bool isDone(Trade t) => doneStates.contains(t.state.raw.toLowerCase());
    bool isFailed(Trade t) => failedStates.contains(t.state.raw.toLowerCase());
    String line(Trade t) =>
        '${_d(t.createdAt!)} ${t.depositAmount} ${t.depositCurrency.title} -> ${t.payoutAmount} ${t.payoutCurrency.title} via ${t.provider.title} (${t.state.title.toLowerCase()}) swap ID: ${t.id}';
    final providers = <String, int>{};
    final got = <String, double>{};
    for (final t in trades) {
      providers[t.provider.title] = (providers[t.provider.title] ?? 0) + 1;
      if (isDone(t)) {
        final title = t.payoutCurrency.title;
        got[title] = (got[title] ?? 0) + (double.tryParse(t.payoutAmount.toString()) ?? 0);
      }
    }
    final ranked = providers.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final failed = trades.where(isFailed).toList();
    return [
      '${trades.length} swaps for ${range.describe}, newest first:',
      for (final t in trades.take(12)) '- ${line(t)}',
      'Providers used: ${ranked.map((e) => '${e.key} x${e.value}').join(', ')}. Most used: ${ranked.first.key}.',
      if (got.isNotEmpty)
        'Total received from completed swaps: ${got.entries.map((e) => '${_n(e.value)} ${e.key}').join(', ')}.',
      'Failed swaps: ${failed.length}${failed.isEmpty ? '' : ' (${failed.map(line).join('; ')})'}',
    ].join('\n');
  }

  List<Contact> _contacts() {
    try {
      return CakeHive.box<Contact>(Contact.boxName).values.toList();
    } catch (_) {
      return [];
    }
  }

  List<Contact> matchContacts(String? query) {
    final q = (query ?? '').trim().toLowerCase();
    final all = _contacts();
    if (q.isEmpty) return all;
    final exact = all.where((c) => c.name.toLowerCase() == q).toList();
    if (exact.isNotEmpty) return exact;
    return all.where((c) => c.name.toLowerCase().contains(q)).toList();
  }

  /// The saved contact whose name appears in [text], if exactly one does.
  @override
  String? contactNamedIn(String text) {
    final lower = text.toLowerCase();
    final found = _contacts()
        .where((c) => c.name.trim().isNotEmpty && RegExp('\\b${RegExp.escape(c.name.toLowerCase())}\\b').hasMatch(lower))
        .map((c) => c.name)
        .toSet();
    return found.length == 1 ? found.first : null;
  }

  @override
  String contacts(String? query) {
    final found = matchContacts(query);
    if (found.isEmpty) {
      return (query ?? '').isEmpty ? 'The address book is empty.' : 'No contact matching "$query".';
    }
    return found.map((c) => '- ${c.name} (${c.type.title}): ${c.address}').join('\n');
  }

  @override
  AskCakeToolResult addContact({required String name, required String address, String? coin}) {
    CryptoCurrency currency = _appStore.wallet?.currency ?? CryptoCurrency.btc;
    if (coin != null && coin.isNotEmpty) {
      try {
        currency = CryptoCurrency.fromString(coin.toLowerCase());
      } catch (_) {}
    }
    if (matchContacts(name).any((c) => c.name.toLowerCase() == name.toLowerCase())) {
      return AskCakeToolResult('You already have a contact named $name.');
    }
    return AskCakeToolResult(
      'Ready to save $name with the ${currency.title} address $address. Nothing is saved until you review and tap Save.',
      action: AskCakeAddContactAction(name: name, address: address, currency: currency),
    );
  }

  @override
  AskCakeToolResult send({required String recipient, required double amount, required bool fiat}) {
    final wallet = _appStore.wallet;
    if (wallet == null) return const AskCakeToolResult('No wallet is open.');
    var value = amount;
    if (fiat) {
      final price = _price;
      if (price == null || price == 0) {
        return AskCakeToolResult(
            'I can\'t convert from $_fiat right now because no price is available. Tell me the amount in $coin instead.');
      }
      value = double.parse((amount / price).toStringAsFixed(6));
    }
    String address;
    String who;
    if (recipient.length >= 26 && !recipient.contains(' ')) {
      address = recipient;
      who = recipient;
    } else {
      final found = matchContacts(recipient);
      if (found.isEmpty) {
        return AskCakeToolResult(
            'I couldn\'t find a contact named "$recipient". Paste their $coin address, or add them as a contact first.');
      }
      final usable = found.where((c) => c.type == wallet.currency).toList();
      if (usable.isEmpty) {
        final c = found.first;
        return AskCakeToolResult(
            '${c.name} only has a ${c.type.title} address saved, which can\'t receive $coin from this wallet. Nothing was prepared.');
      }
      address = usable.first.address;
      who = '${usable.first.name} ($address)';
    }
    final available = _available();
    if (value > available && !demoIgnoreBalance) {
      return AskCakeToolResult(
          'Not enough balance: this wallet has ${_withFiat(available)} available, but you asked to send ${_withFiat(value)}. Nothing was prepared.');
    }
    String scheme = '';
    try {
      scheme = Uri.parse(wallet.walletAddresses.getPaymentUri('0').toString()).scheme;
    } catch (_) {}
    return AskCakeToolResult(
      'Ready to send ${_withFiat(value)} to $who. Nothing is sent until you review and confirm it on the Send screen.',
      action: AskCakeSendAction(address: address, amount: _n(value), scheme: scheme),
    );
  }

  @override
  AskCakeToolResult receive() {
    final wallet = _appStore.wallet;
    if (wallet == null) return const AskCakeToolResult('No wallet is open.');
    return AskCakeToolResult(
      'Your current $coin receive address is:\n${wallet.walletAddresses.address}',
      action: const AskCakeReceiveAction(),
    );
  }

  @override
  DateTime get now => _now();
}

class _Tx {
  const _Tx({
    required this.date,
    required this.incoming,
    required this.amount,
    required this.fee,
    required this.note,
    required this.pending,
  });

  final DateTime date;
  final bool incoming;
  final double amount;
  final double fee;
  final String note;
  final bool pending;
}
