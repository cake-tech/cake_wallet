import "package:cake_wallet/core/key_service.dart";
import "package:cake_wallet/core/trade_monitor.dart";
import "package:cake_wallet/store/anonpay/anonpay_transactions_store.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cake_wallet/store/dashboard/order_filter_store.dart";
import "package:cake_wallet/store/dashboard/orders_store.dart";
import "package:cake_wallet/store/dashboard/payjoin_transactions_store.dart";
import "package:cake_wallet/store/dashboard/trade_filter_store.dart";
import "package:cake_wallet/store/dashboard/trades_store.dart";
import "package:cake_wallet/store/dashboard/transaction_filter_store.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cake_wallet/view_model/dashboard/balance_view_model.dart";
import "package:cake_wallet/view_model/dashboard/dashboard_view_model.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/balance.dart";
import "package:cw_core/balance_card_style_settings.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/db/sqlite.dart" as sqlite;
import "package:cw_core/transaction_direction.dart";
import "package:cw_core/transaction_history.dart";
import "package:cw_core/transaction_info.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mocktail/mocktail.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:sqflite_common_ffi/sqflite_ffi.dart";

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

class _FakeTransaction extends TransactionInfo {
  _FakeTransaction({required String id, required DateTime date}) {
    this.id = id;
    this.date = date;
    amount = Money.fromInt(1, CryptoCurrency.eth);
    direction = TransactionDirection.incoming;
    isPending = false;
  }
}

class _FakeHistory extends TransactionHistoryBase<TransactionInfo> {
  @override
  Future<void> save() async {}

  @override
  void addOne(TransactionInfo transaction) => transactions[transaction.id] = transaction;

  @override
  void addMany(Map<String, TransactionInfo> transactions) => this.transactions.addAll(transactions);
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

// The transaction reaction is debounced by 300 ms, so wait past it.
Future<void> _settleReactions() => Future<void>.delayed(const Duration(milliseconds: 600));

void main() {
  late DatabaseFactory? originalDatabaseFactory;
  late Database? originalDatabase;

  setUpAll(() {
    originalDatabaseFactory = databaseFactoryOrNull;
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDownAll(() {
    databaseFactoryOrNull = originalDatabaseFactory;
  });

  setUp(() async {
    originalDatabase = sqlite.db;
    sqlite.db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await sqlite.db!.execute("""
      CREATE TABLE ${BalanceCardStyleSettings.tableName} (
        walletInfoId INTEGER,
        accountIndex INTEGER DEFAULT -1,
        gradientIndex INTEGER DEFAULT -1,
        useSpecialDesign BOOLEAN DEFAULT FALSE,
        hidden BOOLEAN DEFAULT FALSE,
        backgroundImagePath TEXT DEFAULT "",
        iconStyleIndex INTEGER DEFAULT 0,
        isGradientOnly BOOLEAN DEFAULT FALSE,
        cardOrder INTEGER DEFAULT 0,
        PRIMARY KEY (walletInfoId, accountIndex)
      )
    """);
  });

  tearDown(() async {
    await sqlite.db?.close();
    sqlite.db = originalDatabase;
  });

  test(
    "a stored replacement redraws its row even when only a field outside the identity changes",
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final sharedPreferences = await SharedPreferences.getInstance();
      final history = _FakeHistory();
      final wallet = _MockWallet();
      final walletInfo = _MockWalletInfo();
      final appStore = _MockAppStore();
      final settingsStore = _MockSettingsStore();
      final tradesStore = _MockTradesStore();
      final tradeMonitor = _MockTradeMonitor();

      when(() => appStore.wallet).thenReturn(wallet);
      when(() => wallet.hasNativeAccounts).thenReturn(false);
      when(() => wallet.name).thenReturn("Ethereum Wallet");
      when(() => wallet.id).thenReturn("ethereum-wallet");
      when(() => wallet.type).thenReturn(WalletType.ethereum);
      when(() => wallet.currency).thenReturn(CryptoCurrency.eth);
      when(() => wallet.walletInfo).thenReturn(walletInfo);
      when(() => walletInfo.internalId).thenReturn(7);
      when(() => walletInfo.showSeedBackupReminder).thenReturn(false);
      when(() => walletInfo.isMultiAccountsEnabled).thenReturn(false);
      when(() => wallet.transactionHistory).thenReturn(history);
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
        sharedPreferences: sharedPreferences,
        keyService: _MockKeyService(),
      );

      final original = _FakeTransaction(id: "tx", date: DateTime.utc(2024, 1, 1));
      history.addOne(original);
      await _settleReactions();

      expect(viewModel.transactions, hasLength(1));
      expect(viewModel.transactions.single.transaction, same(original));

      // Only `date` changes: it is not in the row identity string or the watch value's hash fields.
      final replacement = _FakeTransaction(id: "tx", date: DateTime.utc(2024, 2, 2));
      history.addOne(replacement);
      await _settleReactions();

      expect(viewModel.transactions, hasLength(1));
      expect(viewModel.transactions.single.transaction, same(replacement));
    },
  );
}
