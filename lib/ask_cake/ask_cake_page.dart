import 'package:cake_wallet/ask_cake/ask_cake_app_actions.dart';
import 'package:flutter/services.dart';
import 'package:cake_wallet/ask_cake/ask_cake_demo_data.dart';
import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/cake_pay/src/cards/cake_pay_cards_page.dart';
import 'package:cake_wallet/core/auth_service.dart';
import 'package:cake_wallet/core/csv_export_service.dart';
import 'package:cake_wallet/ask_cake/ask_cake_engine.dart';
import 'package:cake_wallet/ask_cake/ask_cake_guards.dart';
import 'package:cake_wallet/ask_cake/ask_cake_loading.dart';
import 'package:cake_wallet/ask_cake/ask_cake_router_store.dart';
import 'package:cake_wallet/ask_cake/ask_cake_usage_log.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cake_wallet/ask_cake/ask_cake_model.dart';
import 'package:cake_wallet/ask_cake/ask_cake_router.dart';
import 'package:cake_wallet/ask_cake/ask_cake_tools.dart';
import 'package:cake_wallet/ask_cake/selftest/ask_cake_selftest_page.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/contact.dart';
import 'package:cake_wallet/entities/contact_record.dart';
import 'package:cake_wallet/new-ui/modal_navigator.dart';
import 'package:cake_wallet/new-ui/pages/buy_sell/buy_sell_amount_page.dart';
import 'package:cake_wallet/new-ui/pages/receive_page.dart';
import 'package:cake_wallet/new-ui/pages/settings_page.dart';
import 'package:cake_wallet/new-ui/pages/swap_page.dart';
import 'package:cake_wallet/new-ui/services/wallet_switch_service.dart';
import 'package:cake_wallet/new-ui/viewmodels/swap/bloc/swap_bloc.dart';
import 'package:cake_wallet/view_model/buy/buy_sell_view_model.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/unspent_coin_type.dart';
import 'package:flutter/cupertino.dart';
import 'package:cake_wallet/new-ui/pages/send_page.dart';
import 'package:cake_wallet/router.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/store/dashboard/fiat_conversion_store.dart';
import 'package:cake_wallet/utils/payment_request.dart';
import 'package:cw_core/cake_hive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:url_launcher/url_launcher.dart';

class _Message {
  _Message.user(this.text)
      : fromUser = true,
        action = null,
        detail = null,
        sourceUrl = null,
        copyables = const [],
        options = const [];

  _Message.assistant(this.text,
      {this.action, this.detail, this.sourceUrl, this.options = const [], this.copyables = const []})
      : fromUser = false;

  /// Reply buttons under a question; cleared once one is tapped or a new message is sent.
  List<AskCakeOption> options;

  final String? sourceUrl;

  /// Values with a copy button (swap IDs for support).
  final List<AskCakeCopyable> copyables;

  final String text;
  final bool fromUser;
  final AskCakeAction? action;
  final String? detail;
}

/// Shows the screen registered for a route name as the first page of a sheet.
class _RoutePage extends StatefulWidget {
  const _RoutePage(this.route, this.arguments);

  final String route;
  final Object? arguments;

  @override
  State<_RoutePage> createState() => _RoutePageState();
}

class _RoutePageState extends State<_RoutePage> {
  Widget? _page;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_page != null) return;
    final route = createRoute(RouteSettings(name: widget.route, arguments: widget.arguments));
    _page = switch (route) {
      MaterialPageRoute<dynamic>() => route.builder(context),
      CupertinoPageRoute<dynamic>() => route.builder(context),
      _ => const Center(child: Text('This screen could not be opened from here.')),
    };
  }

  @override
  Widget build(BuildContext context) => Stack(children: [
        _page!,
        // Some of these screens have no close button when shown first in a sheet;
        // the handle shows that the sheet can be pulled down.
        Align(
          alignment: Alignment.topCenter,
          child: IgnorePointer(
            child: Container(
              margin: const EdgeInsets.only(top: 6),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ]);
}

/// Demo chat screen for the on-device "Ask Cake" assistant.
class AskCakePage extends StatefulWidget {
  /// Whether each reply shows how it was routed. Testers switch it on from the hidden test page.
  static final showRoutingDetails = ValueNotifier<bool>(kDebugMode);

  const AskCakePage({super.key});

  @override
  State<AskCakePage> createState() => _AskCakePageState();
}

class _AskCakePageState extends State<AskCakePage> {
  final _model = AppleFoundationLanguageModel();
  late final AskCakeTools _tools =
      AskCakeTools(getIt.get<AppStore>(), getIt.get<FiatConversionStore>());
  final _router = CoreMlAskCakeRouter();
  late final AskCakeAppActions _app = AskCakeAppActions(getIt.get<AppStore>(), getIt.get<FiatConversionStore>());
  final _store = AskCakeRouterStore();
  late Future<AskCakeEngine> _engine;
  String _routerStatus = 'router: loading';

  _Stage _stage = _Stage.checking;
  bool _introSeen = true;
  bool _needsDownload = false;
  bool _engineReady = false;
  bool _celebrate = false;
  double _progress = 0;
  String? _downloadProblem;

  static const _introSeenKey = 'ask_cake_intro_seen';

  /// Runs as the page opens: the language pack starts loading at once when it
  /// is already on the device, and the first-open explainer covers the wait.
  Future<void> _boot() async {
    final preferences = await SharedPreferences.getInstance();
    await AskCakeUsageLog.load();
    final path = await _store.locate();
    _introSeen = preferences.getBool(_introSeenKey) ?? false;
    _needsDownload = path == null && _store.canDownload;
    if (!_needsDownload) _beginLoading(path);
    if (!mounted) return;
    setState(() {
      if (!_introSeen) {
        _stage = _Stage.welcome;
      } else if (_needsDownload) {
        _stage = _Stage.downloading;
      } else {
        _stage = _engineReady ? _Stage.ready : _Stage.loading;
      }
    });
    // Someone who already agreed to the download gets a newer pack without being asked again.
    if (_introSeen && _needsDownload) _download();
  }

  void _beginLoading(String? path) {
    final started = DateTime.now();
    _engine = _createEngine(path);
    _engine.then((_) async {
      _engineReady = true;
      if (!mounted || _stage != _Stage.loading) return;
      // A quick load goes straight to the chat; a wait that was long enough to watch ends with confetti.
      if (DateTime.now().difference(started) > const Duration(milliseconds: 700)) {
        setState(() => _celebrate = true);
        await Future<void>.delayed(const Duration(milliseconds: 1100));
        if (!mounted) return;
      }
      setState(() => _stage = _Stage.ready);
    });
  }

  Future<void> _download() async {
    setState(() {
      _stage = _Stage.downloading;
      _downloadProblem = null;
      _progress = 0;
    });
    try {
      final path = await _store.download(onProgress: (fraction) {
        if (mounted && (fraction - _progress).abs() >= 0.01) setState(() => _progress = fraction);
      });
      _needsDownload = false;
      if (!mounted) return;
      setState(() => _stage = _Stage.loading);
      _beginLoading(path);
    } on AskCakeRouterDownloadException catch (e) {
      if (!mounted) return;
      setState(() {
        _stage = _Stage.failed;
        _downloadProblem = switch (e.code) {
          'network' => 'The download was interrupted. Check your connection and try again.',
          'checksum' => 'The download did not arrive intact, so it was discarded. Please try again.',
          _ => 'The download is not available right now. Please try again later.',
        };
      });
    }
  }

  /// The user finished the first-open explainer.
  Future<void> _continueFromWelcome() async {
    (await SharedPreferences.getInstance()).setBool(_introSeenKey, true);
    _introSeen = true;
    if (_needsDownload) return _download();
    if (mounted) setState(() => _stage = _engineReady ? _Stage.ready : _Stage.loading);
  }

  /// Uses the trained router when its model is on this device, and Apple's model for routing otherwise.
  Future<AskCakeEngine> _createEngine(String? path) async {
    final guards = await AskCakeGuards.load();
    final problem = path == null && _store.canDownload ? 'modelMissing' : await _router.prepare(path: path);
    if (mounted) {
      setState(() => _routerStatus =
          problem == null ? 'router: trained, loaded in ${_router.lastLoadMs} ms' : 'router: Apple model ($problem)');
    }
    await _app.loadWallets();
    return AskCakeEngine(_model, _tools, router: problem == null ? _router : null, guards: guards, app: _app);
  }

  final _messages = <_Message>[];
  final _input = TextEditingController();
  final _scroll = ScrollController();
  AskCakeAvailability? _availability;
  bool _busy = false;
  bool get _showDetail => AskCakePage.showRoutingDetails.value;

  static const _suggestions = [
    'What\'s my balance?',
    'How much did I spend last month?',
    'Show my swaps',
    'Send 0.01 to Alice',
  ];

  @override
  void initState() {
    super.initState();
    _model.availability().then((value) {
      if (mounted) setState(() => _availability = value);
    });
    AskCakePage.showRoutingDetails.addListener(_refresh);
    _boot();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AskCakePage.showRoutingDetails.removeListener(_refresh);
    if (_engineReady) _engine.then((engine) => engine.reset());
    _router.release();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty || _busy) return;
    _input.clear();
    // Debug builds only: "/do" presses the newest action button and "/opt N" the Nth reply
    // button, so automated UI checks do not depend on finding buttons on screen.
    if (kDebugMode && text.startsWith('/')) {
      final last = _messages.lastWhere((m) => !m.fromUser, orElse: () => _Message.user(''));
      final index = int.tryParse(text.replaceFirst('/opt', '').trim());
      if (text == '/do' && last.action != null) {
        debugPrint('ASKCAKE DO=${last.action!.buttonLabel}');
        _perform(last.action!);
      } else if (index != null && index < last.options.length) {
        debugPrint('ASKCAKE OPT=${last.options[index].label}');
        await _choose(last.options[index]);
      }
      return;
    }
    await _exchange(text, (engine) => engine.ask(text));
  }

  Future<void> _choose(AskCakeOption option) {
    AskCakeUsageLog.followUp('picked', option.label);
    return _exchange(option.label, (engine) => engine.choose(option));
  }

  Future<void> _exchange(String text, Future<AskCakeReply> Function(AskCakeEngine) run) async {
    if (_busy) return;
    setState(() {
      for (final message in _messages) {
        message.options = const [];
      }
      _messages.add(_Message.user(text));
      _busy = true;
    });
    _scrollDown();
    final reply = await run(await _engine);
    if (kDebugMode) {
      debugPrint('ASKCAKE Q=${text.replaceAll('\n', ' ')} ROUTE=${reply.route} '
          'T=${reply.elapsed.inMilliseconds}ms ACTION=${reply.action?.buttonLabel ?? '-'} '
          'A=${reply.text.replaceAll('\n', ' / ')}');
    }
    AskCakeUsageLog.exchange(
        message: text,
        route: reply.route,
        confidence: reply.routerConfidence,
        offered: reply.action?.buttonLabel,
        options: [for (final option in reply.options) option.label]);
    if (!mounted) return;
    setState(() {
      _messages.add(_Message.assistant(
        reply.text,
        action: reply.action,
        sourceUrl: reply.sourceUrl,
        options: reply.options,
        copyables: reply.copyables,
        detail: '${reply.route} · ${(reply.elapsed.inMilliseconds / 1000).toStringAsFixed(1)}s'
            '${reply.routerMs == null ? '' : ' · router ${reply.routerMs} ms'}'
            '${reply.routerConfidence == null ? '' : ' · sure ${(reply.routerConfidence! * 100).round()}%'} · $_routerStatus',
      ));
      _busy = false;
    });
    _scrollDown();
  }

  void _scrollDown() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(_scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
        }
      });

  void _openModal(Widget page) => showMaterialModalBottomSheet<void>(
        backgroundColor: Colors.transparent,
        context: context,
        // Kept below the status bar: the pages draw their own close button at the very top.
        builder: (context) => SafeArea(
          bottom: false,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: ModalNavigator(parentContext: context, rootPage: page),
          ),
        ),
      );

  /// Hands a prepared action to the normal wallet UI, where the user confirms it.
  void _perform(AskCakeAction action) {
    AskCakeUsageLog.followUp('pressed', action.buttonLabel);
    switch (action) {
      case AskCakeSendAction():
        final uri = Uri.parse('${action.scheme}:${action.address}?amount=${action.amount}');
        _openModal(getIt.get<NewSendPage>(
            param1: SendPageParams(initialPaymentRequest: PaymentRequest.fromUri(uri))));
      case AskCakeAddContactAction():
        Navigator.of(context).pushNamed(
          Routes.addressBookAddContact,
          arguments: ContactRecord(
            CakeHive.box<Contact>(Contact.boxName),
            Contact(name: action.name, address: action.address, type: action.currency),
          ),
        );
      case AskCakeReceiveAction():
        _openModal(getIt.get<NewReceivePage>(param1: action.lightning, param2: null));
      case AskCakeApplySettingAction():
        _app.apply(action.setting, action.value, context).then(_say);
      case AskCakeOpenRouteAction():
        // These screens are built for a sheet, so they open in one (below the status bar).
        _openModal(_RoutePage(action.route, action.arguments));
      case AskCakeSwitchWalletAction():
        _switchWallet(action.name);
      case AskCakeOpenPageAction():
        _openPage(action);
    }
  }

  void _say(String text) {
    if (kDebugMode) debugPrint('ASKCAKE SAY=$text');
    if (!mounted) return;
    setState(() => _messages.add(_Message.assistant(text, detail: 'result')));
    _scrollDown();
  }

  CryptoCurrency? _coin(String? ticker) {
    if (ticker == null) return null;
    try {
      return CryptoCurrency.fromString(ticker.toLowerCase());
    } catch (_) {
      return null;
    }
  }

  /// Switching goes through the same unlock prompt the wallet list uses.
  void _switchWallet(String name) {
    final target = _app.walletNamed(name);
    if (target == null) return _say('I could not find that wallet any more.');
    getIt.get<AuthService>().authenticateAction(
      context,
      conditionToDetermineIfToUse2FA: getIt.get<AppStore>().settingsStore.shouldRequireTOTP2FAForAccessingWallet,
      onAuthSuccess: (ok) async {
        if (!ok) return;
        try {
          await getIt.get<WalletSwitchService>().switchToWallet(target);
          await _app.loadWallets();
          _say('Switched to ${target.name}.');
        } catch (_) {
          _say('I could not switch to ${target.name}. Try from the Wallets tab.');
        }
      },
    );
  }

  Future<void> _openPage(AskCakeOpenPageAction action) async {
    final dashboard = getIt.get<DashboardViewModel>();
    switch (action.page) {
      case 'swap':
        final page = getIt.get<NewSwapPage>(param1: null, param2: _coin(action.from));
        final to = _coin(action.to);
        if (to != null) page.bloc.add(PayoutCurrencyChanged(to));
        _openModal(page);
      case 'buy':
      case 'sell':
        _openModal(getIt.get<NewBuySellAmountPage>(
            param1: NewBuySellParams(
                mode: action.page == 'buy' ? BuySellPageMode.buy : BuySellPageMode.sell,
                initialCurrency: _coin(action.asset))));
      case 'cakePay':
        Navigator.of(context).push(CupertinoPageRoute<void>(builder: (_) => getIt.get<CakePayCardsPage>()));
      case 'settings':
        showMaterialModalBottomSheet<void>(
          backgroundColor: Colors.transparent,
          context: context,
          builder: (context) => SafeArea(
            bottom: false,
            child: Material(
                child: NewSettingsPage(dashboardViewModel: dashboard, authService: getIt.get<AuthService>())),
          ),
        );
      case 'lightningDeposit':
        final address = await bitcoin!.getUnusedSpakDepositAddress(dashboard.wallet);
        if (!mounted) return;
        _openModal(getIt.get<NewSendPage>(
            param1: SendPageParams(
          initialPaymentRequest: address == null || address.isEmpty
              ? null
              : PaymentRequest.fromUri(Uri.parse('bitcoin:$address')),
          unspentCoinType: UnspentCoinType.nonMweb,
          mode: SendPageModes.lightningDeposit,
        )));
      case 'lightningWithdrawal':
        final address = bitcoin!.getUnusedSegwitAddress(dashboard.wallet);
        _openModal(getIt.get<NewSendPage>(
            param1: SendPageParams(
          initialPaymentRequest: address == null || address.isEmpty
              ? null
              : PaymentRequest.fromUri(Uri.parse('bitcoin:$address')),
          unspentCoinType: UnspentCoinType.lightning,
          mode: SendPageModes.lightningWithdrawal,
        )));
      case 'exportTransactions':
        await getIt.get<CsvExportService>().exportToCsv(dashboard.items, context);
    }
  }

  Future<void> _seedDemoData() async {
    final result =
        await AskCakeDemoData.seed(getIt.get<AppStore>(), getIt.get<FiatConversionStore>());
    if (!mounted) return;
    setState(() => _messages.add(_Message.assistant(result, detail: 'demo')));
    _scrollDown();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final availability = _availability;
    return Material(
      child: Scaffold(
        backgroundColor: colors.surface,
        appBar: AppBar(
          backgroundColor: colors.surface,
          surfaceTintColor: Colors.transparent,
          centerTitle: true,
          title: Column(
            children: [
              // Long-press opens the hidden on-device self-test.
              GestureDetector(
                key: const ValueKey('ask_cake_title'),
                onLongPress: () => Navigator.of(context)
                    .push(MaterialPageRoute<void>(builder: (_) => const AskCakeSelfTestPage())),
                child: const Text('Ask Cake', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              ),
              Text(
                'Private · runs on your phone',
                key: const ValueKey('ask_cake_model_label'),
                style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
              ),
            ],
          ),
          actions: [
            if (kDebugMode)
              IconButton(
                key: const ValueKey('ask_cake_seed_demo_button'),
                tooltip: 'Seed demo data',
                icon: const Icon(Icons.science_outlined),
                onPressed: _seedDemoData,
              ),
            if (kDebugMode)
              IconButton(
                key: const ValueKey('ask_cake_detail_toggle'),
                tooltip: 'Show routing details',
                icon: Icon(_showDetail ? Icons.bug_report : Icons.bug_report_outlined),
                onPressed: () => AskCakePage.showRoutingDetails.value = !_showDetail,
              ),
          ],
        ),
        body: SafeArea(
          child: availability != null && !availability.available
              ? _Unavailable(text: availability.reasonText)
              : _stage != _Stage.ready
                  ? _gettingReady()
                  : Column(
                  children: [
                    Expanded(
                      child: _messages.isEmpty
                          ? _Intro(onPick: _send, suggestions: _suggestions)
                          : ListView.builder(
                              controller: _scroll,
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                              itemCount: _messages.length + (_busy ? 1 : 0),
                              itemBuilder: (context, index) => index == _messages.length
                                  ? const _Bubble(text: 'Thinking…', fromUser: false, muted: true)
                                  : _MessageView(
                                      message: _messages[index],
                                      showDetail: _showDetail,
                                      onAction: _perform,
                                      onOption: _choose,
                                    ),
                            ),
                    ),
                    _Composer(controller: _input, busy: _busy, onSend: _send),
                  ],
                ),
        ),
      ),
    );
  }

  /// Everything shown before the chat: the first-open explainer, the download and the warm-up.
  Widget _gettingReady() {
    final megabytes = (AskCakeRouterStore.downloadBytes / 1000000).round();
    switch (_stage) {
      case _Stage.checking:
      case _Stage.ready:
        return const SizedBox.shrink();
      case _Stage.welcome:
        return _Welcome(
          megabytes: _needsDownload ? megabytes : null,
          onContinue: _continueFromWelcome,
          onLater: () => Navigator.of(context).maybePop(),
        );
      case _Stage.downloading:
        return _Waiting(
          key: const ValueKey('ask_cake_downloading'),
          progress: _progress,
          lines: const ['Fetching the recipe…', 'Measuring the ingredients…', 'Almost out of the oven…'],
          note: '${(_progress * megabytes).round()} of $megabytes MB · one-time download',
        );
      case _Stage.loading:
        return _Waiting(
          key: const ValueKey('ask_cake_loading'),
          celebrate: _celebrate,
          lines: _celebrate
              ? const ['Ready!']
              : const ['Preheating the oven…', 'Folding in your wallets…', 'Whisking up answers…', 'Adding the icing…'],
          note: 'Everything stays on your phone',
        );
      case _Stage.failed:
        return _DownloadFailed(
            text: _downloadProblem ?? '', onRetry: _download, onLater: () => Navigator.of(context).maybePop());
    }
  }
}

enum _Stage { checking, welcome, downloading, loading, ready, failed }

/// First-open explainer: what Ask Cake does, what stays private, and the download it needs.
class _Welcome extends StatelessWidget {
  const _Welcome({required this.megabytes, required this.onContinue, required this.onLater});

  /// Size of the one-time download, or null when the language pack is already here.
  final int? megabytes;
  final VoidCallback onContinue;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Widget point(IconData icon, String title, String text) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration:
                    BoxDecoration(color: colors.primary.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: colors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.onSurface)),
                    const SizedBox(height: 2),
                    Text(text, style: TextStyle(fontSize: 14, height: 1.35, color: colors.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
        );
    return Column(
      key: const ValueKey('ask_cake_welcome'),
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
            child: Column(
              children: [
                const AskCakeOrbit(size: 210),
                Text('Meet Ask Cake',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: colors.onSurface)),
                const SizedBox(height: 6),
                Text('Your wallet, in plain words.',
                    style: TextStyle(fontSize: 15, color: colors.onSurfaceVariant)),
                const SizedBox(height: 24),
                point(Icons.forum_rounded, 'Ask anything about your wallet',
                    'Balances, what you spent, swaps, fees, prices, or how something in the app works.'),
                point(Icons.bolt_rounded, 'Get things ready in a sentence',
                    'Payments, swaps, contacts and settings are prepared for you. You always review and confirm.'),
                point(Icons.lock_rounded, 'Private by design',
                    'Ask Cake runs on your phone. What you type and what is in your wallet never leave it.'),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
          child: Column(
            children: [
              if (megabytes != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    'Needs a one-time $megabytes MB download to work on your phone. Wi-Fi recommended.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  key: const ValueKey('ask_cake_welcome_continue'),
                  onPressed: onContinue,
                  child: Text(megabytes != null ? 'Download and start' : 'Get started',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              if (megabytes != null)
                TextButton(
                  key: const ValueKey('ask_cake_welcome_later'),
                  onPressed: onLater,
                  child: const Text('Not now'),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The animation with a rotating caption, used for both the download and the warm-up.
class _Waiting extends StatelessWidget {
  const _Waiting({super.key, required this.lines, required this.note, this.progress, this.celebrate = false});

  final List<String> lines;
  final String note;
  final double? progress;
  final bool celebrate;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AskCakeOrbit(progress: progress, celebrate: celebrate),
          const SizedBox(height: 8),
          AskCakeLoadingCaption(key: ValueKey(lines.first), lines: lines),
          const SizedBox(height: 8),
          Text(note, style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant)),
          const SizedBox(height: 60),
        ],
      ),
    );
  }
}

class _DownloadFailed extends StatelessWidget {
  const _DownloadFailed({required this.text, required this.onRetry, required this.onLater});

  final String text;
  final VoidCallback onRetry;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 40, color: colors.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(text,
                key: const ValueKey('ask_cake_download_failed'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, height: 1.35, color: colors.onSurface)),
            const SizedBox(height: 20),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
            TextButton(onPressed: onLater, child: const Text('Not now')),
          ],
        ),
      ),
    );
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView(
      {required this.message, required this.showDetail, required this.onAction, required this.onOption});

  final void Function(AskCakeOption) onOption;

  final _Message message;
  final bool showDetail;
  final void Function(AskCakeAction) onAction;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final action = message.action;
    return Column(
      crossAxisAlignment: message.fromUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        _Bubble(text: message.text, fromUser: message.fromUser),
        if (action != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: FilledButton.icon(
              key: const ValueKey('ask_cake_action_button'),
              onPressed: () => onAction(action),
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: Text(action.buttonLabel),
            ),
          ),
        if (message.options.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (var i = 0; i < message.options.length; i++)
                  i == 0
                      ? FilledButton(
                          key: ValueKey('ask_cake_option_$i'),
                          onPressed: () => onOption(message.options[i]),
                          child: Text(message.options[i].label),
                        )
                      : OutlinedButton(
                          key: ValueKey('ask_cake_option_$i'),
                          onPressed: () => onOption(message.options[i]),
                          child: Text(message.options[i].label),
                        ),
              ],
            ),
          ),
        if (message.copyables.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (var i = 0; i < message.copyables.length; i++)
                  OutlinedButton.icon(
                    key: ValueKey('ask_cake_copy_$i'),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: message.copyables[i].value));
                      AskCakeUsageLog.followUp('copied', 'swap id');
                      debugPrint('ASKCAKE COPIED=${message.copyables[i].value}');
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(content: Text('Swap ID copied')));
                    },
                    icon: const Icon(Icons.copy, size: 16),
                    label: Text(message.copyables[i].label),
                  ),
              ],
            ),
          ),
        if (message.sourceUrl != null)
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 6),
            child: InkWell(
              key: const ValueKey('ask_cake_source_link'),
              onTap: () => launchUrl(Uri.parse(message.sourceUrl!), mode: LaunchMode.externalApplication),
              child: Text('From the docs: ${message.sourceUrl!.replaceFirst('https://', '')}',
                  style: TextStyle(
                      fontSize: 12, color: colors.primary, decoration: TextDecoration.underline)),
            ),
          ),
        if (showDetail && message.detail != null)
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 8),
            child: Text(message.detail!,
                style: TextStyle(fontSize: 10, color: colors.onSurfaceVariant)),
          ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, required this.fromUser, this.muted = false});

  final String text;
  final bool fromUser;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Align(
      alignment: fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: fromUser ? colors.primary : colors.surfaceContainer,
          borderRadius: BorderRadius.circular(18),
        ),
        child: SelectableText(
          text,
          style: TextStyle(
            fontSize: 15,
            height: 1.3,
            color: fromUser
                ? colors.onPrimary
                : muted
                    ? colors.onSurfaceVariant
                    : colors.onSurface,
          ),
        ),
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro({required this.onPick, required this.suggestions});

  final void Function(String) onPick;
  final List<String> suggestions;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 36, color: colors.primary),
            const SizedBox(height: 12),
            Text('Ask about this wallet',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: colors.onSurface)),
            const SizedBox(height: 8),
            Text(
              'Runs entirely on this device. Nothing you type or anything about your wallet leaves your phone, and nothing is sent without your confirmation.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, height: 1.35, color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final suggestion in suggestions)
                  ActionChip(label: Text(suggestion), onPressed: () => onPick(suggestion)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(text,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ),
      );
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.busy, required this.onSend});

  final TextEditingController controller;
  final bool busy;
  final void Function([String?]) onSend;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              key: const ValueKey('ask_cake_input'),
              controller: controller,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: 'Ask about your wallet',
                filled: true,
                fillColor: colors.surfaceContainer,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            key: const ValueKey('ask_cake_send_button'),
            tooltip: 'Send',
            onPressed: busy ? null : onSend,
            icon: const Icon(Icons.arrow_upward),
          ),
        ],
      ),
    );
  }
}
