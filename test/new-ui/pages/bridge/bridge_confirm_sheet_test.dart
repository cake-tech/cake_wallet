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
import "package:cake_wallet/store/app_store.dart";
import "package:cake_wallet/store/bridge_transfers_store.dart";
import "package:cake_wallet/store/dashboard/fiat_conversion_store.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cake_wallet/view_model/bridge/bridge_view_model.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/balance.dart";
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
}

class _WalletManager extends Fake implements WalletManager {}

class _Priority extends Fake implements TransactionPriority {}

class _Burn extends Fake implements PendingTransaction {
  int commits = 0;

  @override
  final String id = "0x0bb37ef659a57985087247ecc425ada9af687e7bd0aa46d984f66acdd29888ad";

  @override
  String? get evmTxHashFromRawHex => null;

  @override
  Future<void> commit() async => commits++;
}

/// Quotes at once and holds the burn back until [burn] completes, like the approval wait does.
class _Evm extends Fake implements EVM {
  final burn = Completer<PendingTransaction>();

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
  }) async =>
      BridgeQuote(nativeFee: BigInt.zero, lzTokenFee: BigInt.zero, tokenFee: BigInt.from(60000));

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
  Future<void> openSheetAndConfirm(WidgetTester tester) async {
    rootNavigator = GlobalKey<NavigatorState>();
    evm = bridge = _Evm();
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

    unawaited(viewModel.executeBridge());
    await tester.pump();
  }

  testWidgets("sends the burn and records the transfer", (tester) async {
    final burn = _Burn();
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
    final burn = _Burn();
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

  testWidgets("does not send the burn once navigation is reset", (tester) async {
    final burn = _Burn();
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
}
