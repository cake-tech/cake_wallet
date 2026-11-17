import "dart:async";
import "dart:convert";
import "dart:io";

import "package:cake_wallet/bitcoin/bitcoin.dart";
import "package:cake_wallet/core/address_resolver/address_resolver_service.dart";
import "package:cake_wallet/core/amount_parsing_proxy.dart";
import "package:cake_wallet/core/anypay/anypay_models.dart";
import "package:cake_wallet/core/anypay/anypay_parser.dart";
import "package:cake_wallet/core/anypay/anypay_service.dart";
import "package:cake_wallet/core/auth_service.dart";
import "package:cake_wallet/core/execution_state.dart";
import "package:cake_wallet/entities/bitcoin_amount_display_mode.dart";
import "package:cake_wallet/entities/contact_record.dart";
import "package:cake_wallet/entities/fiat_currency.dart";
import "package:cake_wallet/entities/transaction_description.dart";
import "package:cake_wallet/entities/wallet_contact.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/locales/locale.dart";
import "package:cake_wallet/new-ui/pages/send_page.dart";
import "package:cake_wallet/new-ui/widgets/modern_button.dart";
import "package:cake_wallet/new-ui/widgets/send_page/floating_icon_button.dart";
import "package:cake_wallet/new-ui/widgets/send_page/recipient_dot_row.dart";
import "package:cake_wallet/new-ui/widgets/send_page/send_address_input.dart";
import "package:cake_wallet/new-ui/widgets/send_page/send_amount_input.dart";
import "package:cake_wallet/new-ui/widgets/send_page/send_confirm_sheet.dart";
import "package:cake_wallet/new-ui/widgets/send_page/send_memo_input.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cake_wallet/store/dashboard/fiat_conversion_store.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cake_wallet/themes/theme_classes/dark_theme.dart";
import "package:cake_wallet/utils/payment_request.dart";
import "package:cake_wallet/view_model/contact_list/contact_list_view_model.dart";
import "package:cake_wallet/view_model/dashboard/balance_view_model.dart";
import "package:cake_wallet/view_model/link_view_model.dart";
import "package:cake_wallet/view_model/send/fees_view_model.dart";
import "package:cake_wallet/view_model/send/send_view_model.dart";
import "package:cake_wallet/view_model/unspent_coins/unspent_coins_list_view_model.dart";
import "package:cake_wallet/view_model/wallet_switcher_view_model.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/balance.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/exceptions.dart";
import "package:cw_core/lnurl.dart";
import "package:cw_core/pending_transaction.dart";
import "package:cw_core/sync_status.dart";
import "package:cw_core/transaction_history.dart";
import "package:cw_core/transaction_info.dart";
import "package:cw_core/unspent_coin_type.dart";
import "package:cw_core/utils/proxy_wrapper.dart";
import "package:cw_core/utils/tor/disabled.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hive/hive.dart";
import "package:mobx/mobx.dart" hide when;
import "package:mocktail/mocktail.dart";

typedef _Wallet = WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo>;

class _MockAppStore extends Mock implements AppStore {}

class _MockSettingsStore extends Mock implements SettingsStore {}

class _MockWallet extends Mock implements _Wallet {}

class _MockTransactionHistory extends Mock implements TransactionHistoryBase<TransactionInfo> {}

class _MockWalletInfo extends Mock implements WalletInfo {}

class _MockFiatConversionStore extends Mock implements FiatConversionStore {}

class _MockAddressResolverService extends Mock implements AddressResolverService {}

class _MockBalanceViewModel extends Mock implements BalanceViewModel {}

class _MockContactListViewModel extends Mock implements ContactListViewModel {}

class _MockDescriptionBox extends Mock implements Box<TransactionDescription> {}

class _MockUnspentCoinsListViewModel extends Mock implements UnspentCoinsListViewModel {}

class _MockFeesViewModel extends Mock implements FeesViewModel {}

class _MockAnyPayService extends Mock implements AnyPayService {}

class _MockLinkViewModel extends Mock implements LinkViewModel {}

class _MockWalletSwitcherViewModel extends Mock implements WalletSwitcherViewModel {}

class _MockAuthService extends Mock implements AuthService {}

class _FakeBuildContext extends Fake implements BuildContext {}

class _Bitcoin extends CWBitcoin {
  _Bitcoin({required this.walletUsesLightning});

  final bool walletUsesLightning;

  @override
  bool useLightning(Object wallet) => walletUsesLightning;
}

class _Funds extends Balance {
  _Funds(CryptoCurrency currency) : super(Money.fromInt(100000, currency), Money.zero(currency));
}

class _FakePendingTransaction with PendingTransaction {
  @override
  String get id => "payment-id";

  @override
  Money get amount => Money.fromInt(1000, CryptoCurrency.btcln);

  @override
  Money get fee => Money.fromInt(1, CryptoCurrency.btcln);

  @override
  String get amountFormatted => amount.toString();

  @override
  String get hex => "";

  @override
  Future<void> commit() async {}

  @override
  Future<Map<String, String>> commitUR() async => {};
}

class _RecipientServer extends HttpOverrides {
  final responses = <String, (int, String)>{};
  final requested = <String>[];
  Future<void>? answersAfter;

  @override
  HttpClient createHttpClient(SecurityContext? context) => _RecipientServerClient(this);
}

class _RecipientServerClient extends Fake implements HttpClient {
  _RecipientServerClient(this.server);

  final _RecipientServer server;

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    server.requested.add(url.toString());
    await server.answersAfter;
    final response = server.responses[url.toString()];
    if (response == null) {
      throw const SocketException("unreachable");
    }
    return _RecipientServerRequest(response);
  }

  @override
  void close({bool force = false}) {}
}

class _RecipientServerHeaders extends Fake implements HttpHeaders {
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  void forEach(void Function(String name, List<String> values) action) {}
}

class _RecipientServerRequest extends Fake implements HttpClientRequest {
  _RecipientServerRequest(this.response);

  final (int, String) response;

  @override
  bool followRedirects = true;

  @override
  int maxRedirects = 5;

  @override
  int contentLength = -1;

  @override
  bool persistentConnection = true;

  @override
  final HttpHeaders headers = _RecipientServerHeaders();

  @override
  Future<void> addStream(Stream<List<int>> stream) => stream.drain<void>();

  @override
  Future<HttpClientResponse> close() async => _RecipientServerResponse(response.$1, response.$2);
}

class _RecipientServerResponse extends StreamView<List<int>> implements HttpClientResponse {
  _RecipientServerResponse(this.statusCode, String body) : super(Stream.value(utf8.encode(body)));

  @override
  final int statusCode;

  @override
  int get contentLength => -1;

  @override
  bool get isRedirect => false;

  @override
  bool get persistentConnection => false;

  @override
  String get reasonPhrase => "";

  @override
  List<RedirectInfo> get redirects => const [];

  @override
  HttpHeaders get headers => _RecipientServerHeaders();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _lnurlUrl = "https://cake.cash/.well-known/lnurlp/konsti";
const _otherLnurlUrl = "https://cake.cash/.well-known/lnurlp/seth";
const _onChainAddress = "bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq";
const _invoiceWithMemo =
    "lnbc1u1p5564nxpp5mrklx2pjaggkcfs9r5tfk84wszzy9gypcnrt9yjq7n6uf95s70xqsp59fph78twjra598n2mll2arw5enluy7a4uf4y9a94ddd30hm98njsxq9z0rgqnp4qvyndeaqzman7h898jxm98dzkm0mlrsx36s93smrur7h0azyyuxc5rzjqwghf7zxvfkxq5a6sr65g0gdkv768p83mhsnt0msszapamzx2qvuxqqqqrt49lmtcqqqqqqqqqqq86qq9qrzjq25carzepgd4vqsyn44jrk85ezrpju92xyrk9apw4cdjh6yrwt5jgqqqqrt49lmtcqqqqqqqqqqq86qq9qcqzpgdql2djkuepqw3hjqsmpddjjq4mpd3kx2aq9qyyssq3nf60ey9fgkf0elu2y8j96rx5pm4gx2a976h8yadx83dyg0ltnysrxhep8e2p3yvz4kf597qk3rttgdy72wwqq0mwr8hdht3pqpchyqq0aa9v0";
const _invoiceWithoutMemo =
    "lnbc10n1p5exazppp5szh273r6nzvwydzsdlg0ws0vhxwnc6nqtqt4sjt0vu6x6l8t5csqdqqcqzzsxqrrsssp5nkup6uht7xlfqaj8lxpe5kx0ejum9p4pvv3nlnndr9ykzge3393s9qxpqysgqufh05a7qs0ezeckvmh7tjkr9ngng96nq274twg20z45ysp7afpdrttm2ky73cpjwpjqsmtzzd79w6lyvszgmkanwn8mj0jcfunrwv3qprg3z3j";

final _lnurl = LNURL.encode(_lnurlUrl);
final _otherLnurl = LNURL.encode(_otherLnurlUrl);
final _shieldedZcashAddress = "zs1${"q" * 75}";

String _payRequest({int? commentAllowed}) => jsonEncode({
      "tag": "payRequest",
      "callback": "https://cake.cash/callback",
      "minSendable": 1000,
      "maxSendable": 100000000,
      "metadata": "[]",
      if (commentAllowed != null) "commentAllowed": commentAllowed,
    });

class _SendPage {
  _SendPage.bitcoin({
    bool useLightning = true,
    bool isSoftwareWallet = true,
    UnspentCoinType coinType = UnspentCoinType.lightning,
  }) {
    bitcoin = _Bitcoin(walletUsesLightning: useLightning);
    _setUp(
      type: WalletType.bitcoin,
      funds: [CryptoCurrency.btc, CryptoCurrency.btcln],
      syncStatus: const NotConnectedSyncStatus(),
      isSoftwareWallet: isSoftwareWallet,
      coinType: coinType,
    );
  }

  _SendPage.zcash() {
    _setUp(
      type: WalletType.zcash,
      funds: [CryptoCurrency.zec],
      syncStatus: SyncedSyncStatus(),
      isSoftwareWallet: true,
      coinType: UnspentCoinType.nonMweb,
    );
  }

  final appStore = _MockAppStore();
  final settings = _MockSettingsStore();
  final wallet = _MockWallet();
  final walletInfo = _MockWalletInfo();
  final history = _MockTransactionHistory();
  final fiatStore = _MockFiatConversionStore();
  final balanceViewModel = _MockBalanceViewModel();
  final contacts = _MockContactListViewModel();
  final unspentCoins = _MockUnspentCoinsListViewModel();
  final fees = _MockFeesViewModel();
  final anyPay = _MockAnyPayService();
  final link = _MockLinkViewModel();
  final auth = _MockAuthService();

  late final SendViewModel viewModel;
  List<String>? memosWhenBuilt;
  Exception? prepareError;
  bool authSucceeds = true;

  void _setUp({
    required WalletType type,
    required List<CryptoCurrency> funds,
    required SyncStatus syncStatus,
    required bool isSoftwareWallet,
    required UnspentCoinType coinType,
  }) {
    final currency = funds.first;

    when(() => appStore.wallet).thenReturn(wallet);
    when(() => appStore.settingsStore).thenReturn(settings);
    when(() => appStore.amountParsingProxy)
        .thenReturn(const AmountParsingProxy(BitcoinAmountDisplayMode.satoshiForLightning));

    when(() => settings.fiatCurrency).thenReturn(FiatCurrency.usd);
    when(() => settings.getPriority(any(), chainId: any(named: "chainId")))
        .thenReturn(bitcoin!.getBitcoinTransactionPriorityMedium());
    when(() => settings.usePayjoin).thenReturn(false);
    when(() => settings.languageCode).thenReturn("en");
    when(() => settings.customBitcoinFeeRate).thenReturn(1);
    when(() => settings.shouldRequireTOTP2FAForSendsToContact).thenReturn(false);
    when(() => settings.shouldRequireTOTP2FAForSendsToNonContact).thenReturn(false);
    when(() => settings.shouldRequireTOTP2FAForSendsToInternalWallets).thenReturn(false);

    when(() => wallet.type).thenReturn(type);
    when(() => wallet.currency).thenReturn(currency);
    when(() => wallet.balance).thenReturn(
      ObservableMap.of({for (final funded in funds) funded: _Funds(funded)}),
    );
    when(() => wallet.transactionHistory).thenReturn(history);
    when(() => history.transactions).thenReturn(ObservableMap<String, TransactionInfo>());
    when(() => wallet.chainId).thenReturn(null);
    when(() => wallet.syncStatus).thenReturn(syncStatus);
    when(() => wallet.isTestnet).thenReturn(false);
    when(() => wallet.walletInfo).thenReturn(walletInfo);
    when(() => wallet.isHardwareWallet).thenReturn(!isSoftwareWallet);
    when(() => wallet.isSoftwareWallet).thenReturn(isSoftwareWallet);
    when(() => wallet.hasCoinControl).thenReturn(false);
    when(() => wallet.calculateEstimatedFee(any(), any())).thenReturn(0);
    when(() => wallet.createTransaction(any())).thenAnswer((_) async {
      memosWhenBuilt = viewModel.outputs.map((output) => output.memo).toList();
      final error = prepareError;
      if (error != null) {
        throw error;
      }
      return _FakePendingTransaction();
    });
    when(() => walletInfo.network).thenReturn(null);

    when(() => fiatStore.prices).thenReturn(
      ObservableMap<CryptoCurrency, double>.of({CryptoCurrency.btc: 100000, currency: 100000}),
    );
    when(() => balanceViewModel.isFiatDisabled).thenReturn(false);
    when(() => contacts.contacts).thenReturn(ObservableList<ContactRecord>());
    when(() => contacts.walletContacts).thenReturn(<WalletContact>[]);
    when(unspentCoins.initialSetup).thenAnswer((_) async {});
    when(() => fees.hasFees).thenReturn(false);
    when(() => fees.customBitcoinFeeRate).thenReturn(1);

    when(() => anyPay.evaluatePaymentRequest(any())).thenAnswer(
      (invocation) async => AnyPayEvaluation(
        request: AnyPayParser.fromPaymentRequest(
          invocation.positionalArguments.first as PaymentRequest,
        ),
        decision: const AnyPayApplyToCurrentWallet(),
      ),
    );
    when(() => link.incomingPaymentLinks).thenAnswer((_) => const Stream<Uri>.empty());
    when(
      () => auth.authenticateAction(
        any(),
        onAuthSuccess: any(named: "onAuthSuccess"),
        conditionToDetermineIfToUse2FA: any(named: "conditionToDetermineIfToUse2FA"),
      ),
    ).thenAnswer((invocation) async {
      if (authSucceeds) {
        Function.apply(invocation.namedArguments[#onAuthSuccess] as Function, [true]);
      }
    });

    viewModel = SendViewModel(
      appStore,
      fiatStore,
      _MockAddressResolverService(),
      balanceViewModel,
      contacts,
      _MockDescriptionBox(),
      null,
      unspentCoins,
      fees,
      coinTypeToSpendFrom: coinType,
    );
  }

  Future<void> pump(WidgetTester tester, {PaymentRequest? scanned}) async {
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: DarkTheme().themeData,
        localizationsDelegates: localizationDelegates,
        supportedLocales: S.delegate.supportedLocales,
        home: Scaffold(
          body: NewSendPage(
            sendViewModel: viewModel,
            anyPayService: anyPay,
            linkViewModel: link,
            walletSwitcherViewModel: _MockWalletSwitcherViewModel(),
            contactListViewModel: contacts,
            authService: auth,
            params: SendPageParams(
              initialPaymentRequest: scanned,
              unspentCoinType: viewModel.coinTypeToSpendFrom,
            ),
          ),
        ),
      ),
    );
    await _settle(tester);
  }

  Future<void> tapSend(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey("send_page_send_button_key")));
    await _settle(tester);
  }

  void verifyAuthenticationRequested() => verify(
        () => auth.authenticateAction(
          any(),
          onAuthSuccess: any(named: "onAuthSuccess"),
          conditionToDetermineIfToUse2FA: any(named: "conditionToDetermineIfToUse2FA"),
        ),
      ).called(1);
}

final _addressField =
    find.descendant(of: find.byType(NewSendAddressInput), matching: find.byType(TextField));

final _amountField =
    find.descendant(of: find.byType(NewSendAmountInput), matching: find.byType(TextField));

final _memoField =
    find.descendant(of: find.byType(NewSendMemoInput), matching: find.byType(TextField));

final _memoInput = find.byType(NewSendMemoInput);
final _invoiceMemo = find.byType(NewSendInvoiceMemo);

final _invoiceMemoField = find.descendant(of: _invoiceMemo, matching: find.byType(TextField));

final _memoPasteButton = find.descendant(of: _memoInput, matching: find.byType(FloatingIconButton));

final _removeRecipientButton = find.byWidgetPredicate(
  (widget) => widget is ModernButton && widget.semanticLabel == S.current.remove,
);

Finder _onConfirmSheet(String text) =>
    find.descendant(of: find.byType(SendConfirmSheet), matching: find.text(text));

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _enterAddress(WidgetTester tester, String address) async {
  await tester.enterText(_addressField, address);
  await _settle(tester);
}

Future<void> _addRecipient(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.add));
  await _settle(tester);
}

Future<void> _selectRecipient(WidgetTester tester, int index) async {
  tester.widget<RecipientDotRow>(find.byType(RecipientDotRow)).onSelected(index);
  await _settle(tester);
}

Future<void> _loadAppFonts() async {
  final fonts = FontLoader("Wix Madefor Text");
  for (final weight in ["Regular", "Medium", "SemiBold", "Bold"]) {
    final bytes = File("assets/fonts/WixMadeforText-$weight.ttf").readAsBytesSync();
    fonts.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await fonts.load();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _RecipientServer server;

  setUpAll(() async {
    await _loadAppFonts();
    S.current = const S();
    CakeTor.instance = CakeTorDisabled();
    registerFallbackValue(WalletType.bitcoin);
    registerFallbackValue(_FakeBuildContext());
    registerFallbackValue(PaymentRequest("", "", "", "", null));
    registerFallbackValue(bitcoin!.getBitcoinTransactionPriorityMedium());
  });

  setUp(() {
    final previousOverrides = HttpOverrides.current;
    final appBitcoin = bitcoin;
    server = _RecipientServer();
    HttpOverrides.global = server;
    addTearDown(() {
      HttpOverrides.global = previousOverrides;
      bitcoin = appBitcoin;
    });
  });

  group("Lightning recipient that takes a comment", () {
    testWidgets("shows the memo field with the recipient's limit once it has answered",
        (tester) async {
      final answer = Completer<void>();
      server.responses[_lnurlUrl] = (200, _payRequest(commentAllowed: 120));
      server.answersAfter = answer.future;
      final page = _SendPage.bitcoin();
      await page.pump(tester);

      await _enterAddress(tester, _lnurl.substring(0, _lnurl.length - 5));
      expect(server.requested, isEmpty);
      expect(_memoInput, findsNothing);

      await _enterAddress(tester, _lnurl);
      expect(server.requested, [_lnurlUrl]);
      expect(_memoInput, findsNothing);

      answer.complete();
      await _settle(tester);

      expect(tester.widget<NewSendMemoInput>(_memoInput).maxMemoLength, 120);
      expect(tester.widget<TextField>(_memoField).maxLength, 120);
    });

    testWidgets("drops the memo when the recipient becomes an on-chain address", (tester) async {
      server.responses[_lnurlUrl] = (200, _payRequest(commentAllowed: 120));
      final page = _SendPage.bitcoin();
      await page.pump(tester);

      await _enterAddress(tester, _lnurl);
      await tester.enterText(_memoField, "Thanks for dinner");
      await _settle(tester);
      expect(page.viewModel.outputs.first.memo, "Thanks for dinner");

      await _enterAddress(tester, _onChainAddress);
      expect(_memoInput, findsNothing);
      expect(page.viewModel.outputs.first.memo, "");

      await _enterAddress(tester, _lnurl);
      expect(server.requested, [_lnurlUrl]);
      expect(tester.widget<TextField>(_memoField).controller!.text, "");
    });

    testWidgets("drops the memo when another Lightning recipient is entered", (tester) async {
      server.responses[_lnurlUrl] = (200, _payRequest(commentAllowed: 120));
      server.responses[_otherLnurlUrl] = (200, _payRequest(commentAllowed: 120));
      final page = _SendPage.bitcoin();
      await page.pump(tester);

      await _enterAddress(tester, _otherLnurl);
      await _enterAddress(tester, _lnurl);
      await tester.enterText(_memoField, "Thanks for dinner");
      await _settle(tester);
      expect(page.viewModel.outputs.first.memo, "Thanks for dinner");

      await _enterAddress(tester, _otherLnurl);

      expect(server.requested, [_otherLnurlUrl, _lnurlUrl]);
      expect(tester.widget<TextField>(_memoField).controller!.text, "");
      expect(page.viewModel.outputs.first.memo, "");
    });

    testWidgets("shows the memo field once a username has been resolved to its LNURL",
        (tester) async {
      server.responses[_lnurlUrl] = (200, _payRequest(commentAllowed: 255));
      final page = _SendPage.bitcoin();
      await page.pump(tester);

      await _enterAddress(tester, "konsti@cake.cash");
      expect(_memoInput, findsNothing);
      expect(server.requested, isEmpty);

      runInAction(() => page.viewModel.outputs.first.extractedAddress = _lnurl);
      await _settle(tester);

      expect(server.requested, [_lnurlUrl]);
      expect(tester.widget<NewSendMemoInput>(_memoInput).maxMemoLength, 255);
    });

    testWidgets("passes the memo to the wallet and shows it before confirming", (tester) async {
      server.responses[_lnurlUrl] = (200, _payRequest(commentAllowed: 255));
      final page = _SendPage.bitcoin();
      await page.pump(tester);

      await _enterAddress(tester, _lnurl);
      await tester.enterText(_amountField, "1000");
      await tester.enterText(_memoField, "Thanks for dinner");
      await _settle(tester);
      await page.tapSend(tester);

      expect(_onConfirmSheet("Memo"), findsOneWidget);
      expect(_onConfirmSheet("Thanks for dinner"), findsOneWidget);
      expect(page.viewModel.state, isA<ExecutedSuccessfullyState>());
      expect(page.memosWhenBuilt, ["Thanks for dinner"]);
    });

    testWidgets("explains a memo the recipient refuses", (tester) async {
      server.responses[_lnurlUrl] = (200, _payRequest(commentAllowed: 255));
      final page = _SendPage.bitcoin()..prepareError = TransactionMemoNotAcceptedException(0);
      await page.pump(tester);

      await _enterAddress(tester, _lnurl);
      await tester.enterText(_amountField, "1000");
      await tester.enterText(_memoField, "Thanks");
      await _settle(tester);
      await page.tapSend(tester);

      expect((page.viewModel.state as FailureState).error, "The recipient doesn't accept a memo");
      expect(_onConfirmSheet("The recipient doesn't accept a memo"), findsWidgets);
      expect(
        page.viewModel.translateErrorMessage(
          TransactionMemoNotAcceptedException(40),
          WalletType.bitcoin,
          CryptoCurrency.btc,
        ),
        "The recipient accepts memos up to 40 characters",
      );
    });

    testWidgets("hands the wallet a pasted memo that is over the limit", (tester) async {
      const pasted = "This pasted memo is far longer than the recipient allows";
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async => call.method == "Clipboard.getData" ? {"text": pasted} : null,
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );
      server.responses[_lnurlUrl] = (200, _payRequest(commentAllowed: 32));
      final page = _SendPage.bitcoin();
      await page.pump(tester);

      await _enterAddress(tester, _lnurl);
      await tester.enterText(_amountField, "1000");
      await tester.enterText(_memoField, "Hi");
      await _settle(tester);
      tester.widget<FloatingIconButton>(_memoPasteButton).onPressed();
      await _settle(tester);
      await page.tapSend(tester);

      expect(tester.widget<TextField>(_memoField).controller!.text, pasted);
      expect(page.memosWhenBuilt, [pasted]);
    });

    testWidgets("hands the wallet a memo with emoji as typed", (tester) async {
      server.responses[_lnurlUrl] = (200, _payRequest(commentAllowed: 10));
      final page = _SendPage.bitcoin();
      await page.pump(tester);

      await _enterAddress(tester, _lnurl);
      await tester.enterText(_memoField, "😀😀😀😀😀😀");
      await _settle(tester);

      expect(page.viewModel.outputs.first.memo, "😀😀😀😀😀😀");
    });
  });

  group("Lightning recipient among several recipients", () {
    testWidgets("keeps the memo with the first recipient and drops it when that one changes",
        (tester) async {
      server.responses[_lnurlUrl] = (200, _payRequest(commentAllowed: 120));
      server.responses[_otherLnurlUrl] = (200, _payRequest(commentAllowed: 120));
      final page = _SendPage.bitcoin(coinType: UnspentCoinType.nonMweb);
      await page.pump(tester);

      await _enterAddress(tester, _otherLnurl);
      await _enterAddress(tester, _lnurl);
      await tester.enterText(_memoField, "Thanks for dinner");
      await _settle(tester);
      await _addRecipient(tester);
      await _addRecipient(tester);
      await _selectRecipient(tester, 0);
      expect(tester.widget<TextField>(_memoField).controller!.text, "Thanks for dinner");

      await _enterAddress(tester, _otherLnurl);

      expect(tester.widget<TextField>(_memoField).controller!.text, "");
      expect(page.viewModel.outputs.first.memo, "");
    });

    testWidgets("offers no memo for a Lightning recipient that isn't the first", (tester) async {
      server.responses[_lnurlUrl] = (200, _payRequest(commentAllowed: 120));
      final page = _SendPage.bitcoin(coinType: UnspentCoinType.nonMweb);
      await page.pump(tester);

      await _enterAddress(tester, _lnurl);
      await _enterAddress(tester, _onChainAddress);
      await _addRecipient(tester);
      await _enterAddress(tester, _lnurl);

      expect(server.requested, [_lnurlUrl]);
      expect(_memoInput, findsNothing);
    });

    testWidgets("still asks and clears after the first recipient was removed", (tester) async {
      server.responses[_lnurlUrl] = (200, _payRequest(commentAllowed: 120));
      server.responses[_otherLnurlUrl] = (200, _payRequest(commentAllowed: 120));
      final page = _SendPage.bitcoin(coinType: UnspentCoinType.nonMweb);
      await page.pump(tester);

      await _enterAddress(tester, _otherLnurl);
      await _addRecipient(tester);
      await _selectRecipient(tester, 0);
      tester.widget<ModernButton>(_removeRecipientButton).onPressed();
      await _settle(tester);
      expect(page.viewModel.outputs, hasLength(1));

      await _enterAddress(tester, _lnurl);
      expect(server.requested, [_otherLnurlUrl, _lnurlUrl]);
      await tester.enterText(_memoField, "Thanks for dinner");
      await _settle(tester);
      expect(page.viewModel.outputs.first.memo, "Thanks for dinner");

      await _enterAddress(tester, _otherLnurl);

      expect(tester.widget<TextField>(_memoField).controller!.text, "");
      expect(page.viewModel.outputs.first.memo, "");
    });
  });

  group("Lightning recipient without a known comment limit", () {
    testWidgets("shows no memo field when the recipient takes no comment", (tester) async {
      server.responses[_lnurlUrl] = (200, _payRequest());
      final page = _SendPage.bitcoin();
      await page.pump(tester);

      await _enterAddress(tester, _lnurl);

      expect(server.requested, [_lnurlUrl]);
      expect(_memoInput, findsNothing);
    });

    testWidgets("offers a 255 character memo when the recipient can't be asked", (tester) async {
      server.responses[_lnurlUrl] = (500, "Bad gateway");
      final page = _SendPage.bitcoin();
      await page.pump(tester);

      await _enterAddress(tester, _lnurl);
      expect(tester.widget<NewSendMemoInput>(_memoInput).maxMemoLength, 255);

      await _enterAddress(tester, LNURL.encode("https://offline.example/lnurlp/bob"));
      expect(server.requested.last, "https://offline.example/lnurlp/bob");
      expect(tester.widget<NewSendMemoInput>(_memoInput).maxMemoLength, 255);
    });

    testWidgets("shows no memo field for an LNURL that isn't a pay request", (tester) async {
      const withdrawUrl = "https://cake.cash/withdraw";
      server.responses[withdrawUrl] = (200, jsonEncode({"tag": "withdrawRequest"}));
      final page = _SendPage.bitcoin();
      await page.pump(tester);

      await _enterAddress(tester, LNURL.encode(withdrawUrl));

      expect(server.requested, [withdrawUrl]);
      expect(_memoInput, findsNothing);
    });

    testWidgets("asks nothing of a recipient that isn't https or onion", (tester) async {
      final page = _SendPage.bitcoin();
      await page.pump(tester);

      await _enterAddress(tester, LNURL.encode("http://192.168.1.1/lnurlp/bob"));

      expect(server.requested, isEmpty);
      expect(_memoInput, findsNothing);
    });
  });

  group("Lightning invoice", () {
    testWidgets("shows the invoice's memo read-only and sends none", (tester) async {
      final page = _SendPage.bitcoin();
      await page.pump(tester);

      await _enterAddress(tester, _invoiceWithMemo);

      final invoiceMemo = tester.widget<TextField>(_invoiceMemoField);
      expect(_memoInput, findsNothing);
      expect(invoiceMemo.controller!.text, "Send to Cake Wallet");
      expect(invoiceMemo.readOnly, isTrue);
      expect(page.viewModel.outputs.first.memo, "");
      expect(server.requested, isEmpty);
    });

    testWidgets("shows nothing for an invoice without a memo", (tester) async {
      final page = _SendPage.bitcoin();
      await page.pump(tester);

      await _enterAddress(tester, _invoiceWithoutMemo);

      expect(_memoInput, findsNothing);
      expect(_invoiceMemo, findsNothing);
      expect(server.requested, isEmpty);
    });

    for (final scanned in [
      "LIGHTNING:${_invoiceWithMemo.toUpperCase()}",
      "Lightning:$_invoiceWithMemo",
    ]) {
      testWidgets("accepts a scanned ${scanned.substring(0, 14)} invoice", (tester) async {
        final page = _SendPage.bitcoin();
        await page.pump(tester, scanned: PaymentRequest.fromString(scanned));

        expect(tester.widget<TextField>(_addressField).controller!.text, scanned);
        expect(tester.widget<TextField>(_amountField).controller!.text, "100");
        expect(_invoiceMemo, findsOneWidget);

        await page.tapSend(tester);

        expect(_onConfirmSheet("Memo"), findsOneWidget);
        expect(_onConfirmSheet("Send to Cake Wallet"), findsOneWidget);
        expect(page.memosWhenBuilt, [""]);
      });
    }
  });

  group("Bitcoin wallet that can't pay over Lightning", () {
    for (final (reason, page) in [
      ("with Lightning turned off", () => _SendPage.bitcoin(useLightning: false)),
      ("on a hardware device", () => _SendPage.bitcoin(isSoftwareWallet: false)),
    ]) {
      testWidgets("asks the recipient nothing and shows no memo $reason", (tester) async {
        server.responses[_lnurlUrl] = (200, _payRequest(commentAllowed: 255));
        await page().pump(tester);

        await _enterAddress(tester, _lnurl);
        expect(server.requested, isEmpty);
        expect(_memoInput, findsNothing);

        await _enterAddress(tester, _invoiceWithMemo);
        expect(_invoiceMemo, findsNothing);
      });
    }
  });

  group("On-chain Bitcoin recipient", () {
    testWidgets("shows no memo", (tester) async {
      final page = _SendPage.bitcoin(coinType: UnspentCoinType.nonMweb);
      await page.pump(tester);

      await _enterAddress(tester, _onChainAddress);

      expect(_memoInput, findsNothing);
      expect(_invoiceMemo, findsNothing);
      expect(server.requested, isEmpty);
    });

    testWidgets("drops a leftover memo before the transaction is built", (tester) async {
      final page = _SendPage.bitcoin(coinType: UnspentCoinType.nonMweb)..authSucceeds = false;
      await page.pump(tester);

      await _enterAddress(tester, _onChainAddress);
      await tester.enterText(_amountField, "0.001");
      await _settle(tester);
      runInAction(() => page.viewModel.outputs.first.memo = "meant for someone else");

      await page.tapSend(tester);

      expect(page.viewModel.outputs.first.memo, "");
      page.verifyAuthenticationRequested();
      verifyNever(() => page.wallet.createTransaction(any()));
    });
  });

  group("Zcash recipient", () {
    testWidgets("keeps the memo when the recipient changes", (tester) async {
      final page = _SendPage.zcash();
      await page.pump(tester);

      await _enterAddress(tester, _shieldedZcashAddress);
      await tester.enterText(_memoField, "Rent for May");
      await _settle(tester);
      await _enterAddress(tester, "zs1${"p" * 75}");

      expect(tester.widget<TextField>(_memoField).controller!.text, "Rent for May");
      expect(page.viewModel.outputs.first.memo, "Rent for May");
    });

    testWidgets("keeps its memo field and shows every memo before confirming", (tester) async {
      final page = _SendPage.zcash();
      await page.pump(tester);

      expect(tester.widget<NewSendMemoInput>(_memoInput).maxMemoLength, 512);

      await _enterAddress(tester, _shieldedZcashAddress);
      await tester.enterText(_amountField, "0.1");
      await tester.enterText(_memoField, "Rent for May");
      await _settle(tester);

      await tester.tap(find.byIcon(Icons.add));
      await _settle(tester);
      await _enterAddress(tester, _shieldedZcashAddress);
      await tester.enterText(_amountField, "0.2");
      await tester.enterText(_memoField, "Gift");
      await _settle(tester);
      await page.tapSend(tester);

      expect(page.memosWhenBuilt, ["Rent for May", "Gift"]);
      expect(_onConfirmSheet("Memo"), findsOneWidget);
      expect(_onConfirmSheet("1: Rent for May\n2: Gift"), findsOneWidget);
      expect(server.requested, isEmpty);
    });
  });
}
