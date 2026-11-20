import "dart:async";

import "package:cake_wallet/core/amount_parsing_proxy.dart";
import "package:cake_wallet/entities/bitcoin_amount_display_mode.dart";
import "package:cake_wallet/entities/bridge_transfer.dart";
import "package:cake_wallet/entities/fiat_currency.dart";
import "package:cake_wallet/entities/wallet_manager.dart";
import "package:cake_wallet/evm/evm.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/locales/locale.dart";
import "package:cake_wallet/new-ui/pages/bridge/bridge_confirm_sheet.dart";
import "package:cake_wallet/new-ui/widgets/confirm_swiper.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cake_wallet/store/bridge_transfers_store.dart";
import "package:cake_wallet/store/dashboard/fiat_conversion_store.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cake_wallet/view_model/bridge/bridge_view_model.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/balance.dart";
import "package:cw_core/bridge_quote.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/erc20_token.dart";
import "package:cw_core/pending_transaction.dart";
import "package:cw_core/transaction_history.dart";
import "package:cw_core/transaction_info.dart";
import "package:cw_core/transaction_priority.dart";
import "package:cw_core/wallet_addresses.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mobx/mobx.dart";

const _tokenMessenger = "0x28b5a0e9C621a5BadaA536219b3a228C8168cf5d";

final _usdc = Erc20Token(
  name: "USD Coin",
  symbol: "USDC",
  contractAddress: "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913",
  decimal: 6,
);

class _Balance extends Balance {
  _Balance(Money available) : super(available, Money.zero(available.currency));
}

class _Addresses extends Fake implements WalletAddresses {
  @override
  final String address = "0x70997970C51812dc3A010C7d01b50e0d17dc79C8";
}

class _Wallet extends Fake
    implements WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo> {
  @override
  final WalletType type = WalletType.base;

  @override
  final String name = "Base wallet";

  @override
  final CryptoCurrency currency = CryptoCurrency.baseEth;

  @override
  final WalletAddresses walletAddresses = _Addresses();

  @override
  final balance = ObservableMap<CryptoCurrency, Balance>.of({
    _usdc: _Balance(Money(BigInt.from(50000000), _usdc)),
  });
}

class _AppStore extends Fake implements AppStore {
  @override
  final WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo>? wallet =
      _Wallet();

  @override
  final amountParsingProxy = const AmountParsingProxy(BitcoinAmountDisplayMode.bitcoin);
}

class _TransfersStore extends Fake implements BridgeTransfersStore {
  @override
  final bridgeTransfers = <BridgeTransfer>[];

  @override
  Future<void> addTransfer(BridgeTransfer transfer) async => bridgeTransfers.add(transfer);
}

class _SettingsStore extends Fake implements SettingsStore {
  @override
  final FiatCurrency fiatCurrency = FiatCurrency.usd;

  @override
  bool useBlinkProtection = true;
}

class _WalletManager extends Fake implements WalletManager {}

class _Priority extends Fake implements TransactionPriority {}

class _Transaction extends Fake implements PendingTransaction {
  _Transaction({int fee = 21000, this.sent})
      : fee = Money(BigInt.from(fee), CryptoCurrency.baseEth);

  final Future<void>? sent;
  int commits = 0;

  @override
  final Money fee;

  @override
  final String id = "0x0bb37ef659a57985087247ecc425ada9af687e7bd0aa46d984f66acdd29888ad";

  @override
  String? get evmTxHashFromRawHex => id;

  @override
  Future<void> commit() async {
    commits++;
    await sent;
  }
}

class _Evm extends Fake implements EVM {
  final approval = Completer<PendingTransaction>();
  final burn = Completer<PendingTransaction>();
  Future<void>? quoteDelay;
  String? approvalSpender;
  bool? approvalReceipt;
  (WalletBase, Money, String)? approved;

  @override
  int? getSelectedChainId(WalletBase wallet) => 8453;

  @override
  TransactionPriority getDefaultTransactionPriority() => _Priority();

  @override
  List<ChainInfo> getBridgeDestinationChains(WalletBase wallet, CryptoCurrency token) => const [
        ChainInfo(chainId: 1, name: "Ethereum", shortCode: "eth", currency: CryptoCurrency.eth),
      ];

  @override
  Future<BridgeQuote> quoteBridgeTransfer({
    required WalletBase wallet,
    required CryptoCurrency token,
    required int sourceChainId,
    required int destinationChainId,
    required BigInt amount,
    required String recipientAddress,
  }) async {
    await quoteDelay;

    return BridgeQuote(
      fee: Money(BigInt.from(60000), token),
      receiveAmount: Money(amount - BigInt.from(60000), token),
      approvalSpender: approvalSpender,
    );
  }

  @override
  Future<bool> isApprovalRequired(
    WalletBase wallet,
    String tokenContract,
    String spender,
    BigInt requiredAmount,
  ) async =>
      approvalReceipt != true;

  @override
  Future<PendingTransaction> createTokenApproval(
    WalletBase wallet,
    Money amount,
    String spender,
    TransactionPriority? priority, {
    bool useBlinkProtection = true,
  }) {
    approved = (wallet, amount, spender);
    return approval.future;
  }

  @override
  Future<bool?> getTransactionReceipt(WalletBase wallet, String txHash) async => approvalReceipt;

  @override
  Future<PendingTransaction> executeBridgeTransfer({
    required WalletBase wallet,
    required CryptoCurrency token,
    required int sourceChainId,
    required int destinationChainId,
    required BigInt amount,
    required String recipientAddress,
    required BridgeQuote quote,
    required TransactionPriority priority,
    bool useBlinkProtection = true,
  }) =>
      burn.future;
}

class _BridgePage extends StatefulWidget {
  const _BridgePage(this.viewModel);

  final BridgeViewModel viewModel;

  @override
  State<_BridgePage> createState() => _BridgePageState();
}

class _BridgePageState extends State<_BridgePage> {
  @override
  void dispose() {
    widget.viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextButton(
        onPressed: () =>
            BridgeConfirmSheet.show(context: context, bridgeViewModel: widget.viewModel),
        child: const Text("Open"),
      );
}

void main() {
  late GlobalKey<NavigatorState> rootNavigator;
  late _Evm bridge;
  late _TransfersStore transfers;
  late BridgeViewModel viewModel;

  tearDown(() => evm = null);

  // Built inside the test body: a Completer created in setUp would complete outside the test's
  // fake clock.
  Future<void> openSheet(WidgetTester tester, {String? approvalSpender}) async {
    rootNavigator = GlobalKey<NavigatorState>();
    evm = bridge = _Evm()..approvalSpender = approvalSpender;
    transfers = _TransfersStore();
    viewModel = BridgeViewModel(
      appStore: _AppStore(),
      bridgeTransfersStore: transfers,
      walletManager: _WalletManager(),
      fiatConversionStore: FiatConversionStore()
        ..prices.addAll({_usdc: 1, CryptoCurrency.baseEth: 3000}),
      settingsStore: _SettingsStore(),
    )
      ..setSelectedToken(_usdc)
      ..setDestinationChain(1)
      ..setAmount("10")
      ..setRecipientAddress("0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266");

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: rootNavigator,
        localizationsDelegates: localizationDelegates,
        supportedLocales: S.delegate.supportedLocales,
        // As in the app, the bridge runs in a navigator nested inside a root route.
        home: Material(
          child: Navigator(
            onGenerateRoute: (_) => MaterialPageRoute<void>(builder: (_) => _BridgePage(viewModel)),
          ),
        ),
      ),
    );
    await tester.tap(find.text("Open"));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> openSheetAndConfirm(WidgetTester tester) async {
    await openSheet(tester);

    unawaited(viewModel.executeBridge());
    await tester.pump();
  }

  Future<void> swipe(WidgetTester tester) async {
    tester.widget<ConfirmSwiper>(find.byType(ConfirmSwiper)).onConfirmed();
    await tester.pump();
  }

  testWidgets("keeps the newest quote when an older request answers last", (tester) async {
    final olderAnswer = Completer<void>();
    await openSheet(tester);

    bridge.quoteDelay = olderAnswer.future;
    unawaited(viewModel.loadQuote());
    bridge.quoteDelay = null;
    viewModel.setAmount("20");
    await viewModel.loadQuote();
    olderAnswer.complete();
    await tester.pump();

    expect(viewModel.quote!.receiveAmount.amount, BigInt.from(19940000));
  });

  testWidgets("sends the burn and records the transfer", (tester) async {
    final burn = _Transaction();
    await openSheetAndConfirm(tester);

    bridge.burn.complete(burn);
    await tester.pump(const Duration(milliseconds: 50));

    expect(burn.commits, 1);
    expect(transfers.bridgeTransfers.single.amount, "10");

    // Ends the status polling that the burn started.
    viewModel.dispose();
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets("does not send the burn once the sheet's close button is tapped", (tester) async {
    final burn = _Transaction();
    await openSheetAndConfirm(tester);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    bridge.burn.complete(burn);
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(BridgeConfirmSheet), findsOneWidget, reason: "still closing");
    expect(burn.commits, 0);
    expect(transfers.bridgeTransfers, isEmpty);

    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets("offers no second swipe while a closed sheet's burn is still being sent",
      (tester) async {
    final sent = Completer<void>();
    await openSheetAndConfirm(tester);
    bridge.burn.complete(_Transaction(sent: sent.future));
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text("Open"));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(BridgeConfirmSheet), findsOneWidget);
    expect(find.byType(ConfirmSwiper), findsNothing);

    sent.complete();
    await tester.pump(const Duration(milliseconds: 50));
    viewModel.dispose();
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets("sends one burn when the swipe fires twice", (tester) async {
    final sent = Completer<void>();
    final burn = _Transaction(sent: sent.future);
    await openSheet(tester);

    final swiper = tester.widget<ConfirmSwiper>(find.byType(ConfirmSwiper));
    swiper.onConfirmed();
    swiper.onConfirmed();
    bridge.burn.complete(burn);
    await tester.pump(const Duration(milliseconds: 50));

    expect(burn.commits, 1);
    expect(find.byType(ConfirmSwiper), findsNothing, reason: "the burn is still being sent");

    sent.complete();
    await tester.pump(const Duration(milliseconds: 50));
    viewModel.dispose();
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets("does not send a burn whose fee could not be estimated", (tester) async {
    final burn = _Transaction(fee: 0);
    await openSheetAndConfirm(tester);

    bridge.burn.complete(burn);
    await tester.pump(const Duration(milliseconds: 50));

    expect(burn.commits, 0);
    expect(transfers.bridgeTransfers, isEmpty);
  });

  testWidgets("does not send the burn once navigation is reset", (tester) async {
    final burn = _Transaction();
    await openSheetAndConfirm(tester);

    unawaited(
      rootNavigator.currentState!.pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const SizedBox()),
        (route) => false,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(BridgeConfirmSheet), findsNothing);

    bridge.burn.complete(burn);
    await tester.pump(const Duration(milliseconds: 50));

    expect(burn.commits, 0);
    expect(transfers.bridgeTransfers, isEmpty);
  });

  testWidgets("asks for the approval first and sends the burn on a second swipe", (tester) async {
    final approval = _Transaction();
    final burn = _Transaction();
    await openSheet(tester, approvalSpender: _tokenMessenger);
    bridge.burn.complete(burn);
    expect(bridge.approved, isNull);

    await swipe(tester);
    bridge.approval.complete(approval);
    await tester.pump(const Duration(milliseconds: 50));

    final unlimited = Money((BigInt.one << 256) - BigInt.one, _usdc);
    expect(bridge.approved, (viewModel.wallet, unlimited, _tokenMessenger));
    expect(approval.commits, 1);

    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(ConfirmSwiper), findsNothing, reason: "the approval is not mined yet");

    bridge.approvalReceipt = true;
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(burn.commits, 0);

    await swipe(tester);
    await tester.pump(const Duration(milliseconds: 50));

    expect(approval.commits, 1);
    expect(burn.commits, 1);

    viewModel.dispose();
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets("sends one approval when the swipe fires twice", (tester) async {
    final approval = _Transaction();
    await openSheet(tester, approvalSpender: _tokenMessenger);

    final swiper = tester.widget<ConfirmSwiper>(find.byType(ConfirmSwiper));
    swiper.onConfirmed();
    swiper.onConfirmed();
    bridge.approval.complete(approval);
    await tester.pump(const Duration(milliseconds: 50));

    expect(approval.commits, 1);
    expect(find.byType(ConfirmSwiper), findsNothing, reason: "the approval is not mined yet");

    bridge.approvalReceipt = true;
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets("does not send the approval once the sheet's close button is tapped", (tester) async {
    final approval = _Transaction();
    await openSheet(tester, approvalSpender: _tokenMessenger);

    await swipe(tester);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    bridge.approval.complete(approval);
    await tester.pump(const Duration(milliseconds: 50));

    expect(approval.commits, 0);

    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets("does not send an approval whose fee could not be estimated", (tester) async {
    final approval = _Transaction(fee: 0);
    await openSheet(tester, approvalSpender: _tokenMessenger);

    await swipe(tester);
    bridge.approval.complete(approval);
    await tester.pump(const Duration(milliseconds: 50));

    expect(approval.commits, 0);
  });
}
