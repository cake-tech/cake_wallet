import "dart:async";

import "package:cake_wallet/core/key_service.dart";
import "package:cake_wallet/core/trade_monitor.dart";
import "package:cake_wallet/entities/transaction_description.dart";
import "package:cake_wallet/store/anonpay/anonpay_transactions_store.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cake_wallet/store/dashboard/order_filter_store.dart";
import "package:cake_wallet/store/dashboard/orders_store.dart";
import "package:cake_wallet/store/dashboard/payjoin_transactions_store.dart";
import "package:cake_wallet/store/dashboard/trade_filter_store.dart";
import "package:cake_wallet/store/dashboard/trades_store.dart";
import "package:cake_wallet/store/dashboard/transaction_filter_store.dart";
import "package:cake_wallet/store/dashboard/transaction_notes_store.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cake_wallet/view_model/dashboard/balance_view_model.dart";
import "package:cake_wallet/view_model/dashboard/dashboard_view_model.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/balance.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/transaction_direction.dart";
import "package:cw_core/transaction_history.dart";
import "package:cw_core/transaction_info.dart";
import "package:cw_core/wallet_addresses.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hive/hive.dart";
import "package:mobx/mobx.dart" show ObservableMap;
import "package:mocktail/mocktail.dart";
import "package:shared_preferences/shared_preferences.dart";

class _MockBalanceViewModel extends Mock implements BalanceViewModel {}

class _MockTradeMonitor extends Mock implements TradeMonitor {}

class _MockAppStore extends Mock implements AppStore {}

class _MockTradesStore extends Mock implements TradesStore {}

class _MockTradeFilterStore extends Mock implements TradeFilterStore {}

class _MockOrderFilterStore extends Mock implements OrderFilterStore {}

class _MockTransactionFilterStore extends Mock implements TransactionFilterStore {}

class _MockSettingsStore extends Mock implements SettingsStore {}

class _MockOrdersStore extends Mock implements OrdersStore {}

class _MockAnonpayTransactionsStore extends Mock implements AnonpayTransactionsStore {}

class _MockPayjoinTransactionsStore extends Mock implements PayjoinTransactionsStore {}

class _MockKeyService extends Mock implements KeyService {}

class _MockWallet extends Mock
    implements WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo> {}

class _MockWalletInfo extends Mock implements WalletInfo {}

class _MockWalletAddresses extends Mock implements WalletAddresses {}

class _MockTransactionHistory extends Mock implements TransactionHistoryBase<TransactionInfo> {}

class _FakeDescriptionBox implements Box<TransactionDescription> {
  _FakeDescriptionBox(this.descriptions);

  final List<TransactionDescription> descriptions;

  @override
  Iterable<TransactionDescription> get values => descriptions;

  @override
  Stream<BoxEvent> watch({dynamic key}) => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError("${invocation.memberName} is not faked");
}

class _FakeTransactionInfo extends TransactionInfo {
  _FakeTransactionInfo(String hash) {
    id = hash;
    txHash = hash;
    amount = Money.fromInt(1, CryptoCurrency.nano);
    direction = TransactionDirection.incoming;
    isPending = false;
    date = DateTime.utc(2026, 11, 19);
  }
}

class _DashboardViewModelProbe extends DashboardViewModelBase {
  _DashboardViewModelProbe({
    required super.balanceViewModel,
    required super.accountListViewModelFactory,
    required super.tradeMonitor,
    required super.appStore,
    required super.tradesStore,
    required super.tradeFilterStore,
    required super.orderFilterStore,
    required super.transactionFilterStore,
    required super.settingsStore,
    required super.ordersStore,
    required super.anonpayTransactionsStore,
    required super.payjoinTransactionsStore,
    required super.transactionNotesStore,
    required super.sharedPreferences,
    required super.keyService,
  });

  @override
  void loadFilterItems() {}

  @override
  Future<void> loadCardDesigns() => Future<void>.value();

  @override
  Future<bool> isBackgroundSyncEnabled() async => false;

  @override
  Future<bool> isBatteryOptimizationEnabled() async => false;
}

void main() {
  test("historyNote returns the wallet's note only while Show Notes on History is on", () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final wallet = _MockWallet();
    final walletInfo = _MockWalletInfo();
    final walletAddresses = _MockWalletAddresses();
    final transactionHistory = _MockTransactionHistory();
    final appStore = _MockAppStore();
    final settingsStore = _MockSettingsStore();
    final tradesStore = _MockTradesStore();
    final tradeMonitor = _MockTradeMonitor();

    when(() => appStore.wallet).thenReturn(wallet);
    when(() => wallet.name).thenReturn("Nano Wallet");
    when(() => wallet.id).thenReturn("nano-wallet");
    when(() => wallet.type).thenReturn(WalletType.nano);
    when(() => wallet.hasNativeAccounts).thenReturn(false);
    when(() => wallet.walletInfo).thenReturn(walletInfo);
    when(() => walletInfo.showSeedBackupReminder).thenReturn(false);
    when(() => walletInfo.isMultiAccountsEnabled).thenReturn(false);
    when(() => wallet.walletAddresses).thenReturn(walletAddresses);
    when(() => walletAddresses.primaryAddress).thenReturn("nano_primary");
    when(() => wallet.transactionHistory).thenReturn(transactionHistory);
    when(() => transactionHistory.transactions)
        .thenReturn(ObservableMap<String, TransactionInfo>());
    when(() => settingsStore.mwebAlwaysScan).thenReturn(false);
    when(() => tradesStore.trades).thenReturn(const []);
    when(() => tradeMonitor.monitorActiveTrades(any())).thenReturn(null);

    final viewModel = _DashboardViewModelProbe(
      balanceViewModel: _MockBalanceViewModel(),
      accountListViewModelFactory: () => null,
      tradeMonitor: tradeMonitor,
      appStore: appStore,
      tradesStore: tradesStore,
      tradeFilterStore: _MockTradeFilterStore(),
      orderFilterStore: _MockOrderFilterStore(),
      transactionFilterStore: _MockTransactionFilterStore(),
      settingsStore: settingsStore,
      ordersStore: _MockOrdersStore(),
      anonpayTransactionsStore: _MockAnonpayTransactionsStore(),
      payjoinTransactionsStore: _MockPayjoinTransactionsStore(),
      transactionNotesStore: TransactionNotesStore(
        transactionDescriptionSource: _FakeDescriptionBox([
          TransactionDescription(id: "tx1_nano_primary", transactionNote: "Rent"),
          TransactionDescription(id: "tx2_nano_other", transactionNote: "Other wallet"),
        ]),
      ),
      sharedPreferences: await SharedPreferences.getInstance(),
      keyService: _MockKeyService(),
    );

    when(() => settingsStore.showTransactionNotesInHistory).thenReturn(true);
    expect(viewModel.historyNote(_FakeTransactionInfo("tx1")), "Rent");
    expect(viewModel.historyNote(_FakeTransactionInfo("tx2")), "");

    when(() => settingsStore.showTransactionNotesInHistory).thenReturn(false);
    expect(viewModel.historyNote(_FakeTransactionInfo("tx1")), "");
  });
}
