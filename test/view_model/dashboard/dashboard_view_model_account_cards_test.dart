import "package:cake_wallet/core/address_resolver/yat/yat_store.dart";
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
import "package:cake_wallet/wownero/wownero.dart" as wow;
import "package:cw_core/balance.dart";
import "package:cw_core/balance_card_style_settings.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/db/sqlite.dart" as sqlite;
import "package:cw_core/transaction_history.dart";
import "package:cw_core/transaction_info.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mobx/mobx.dart" show ObservableList, ObservableMap;
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

class _MockYatStore extends Mock implements YatStore {}

class _MockOrdersStore extends Mock implements OrdersStore {}

class _MockAnonpayTransactionsStore extends Mock implements AnonpayTransactionsStore {}

class _MockPayjoinTransactionsStore extends Mock implements PayjoinTransactionsStore {}

class _MockKeyService extends Mock implements KeyService {}

class _MockWallet extends Mock
    implements WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo> {}

class _MockWalletInfo extends Mock implements WalletInfo {}

class _MockTransactionHistory extends Mock implements TransactionHistoryBase<TransactionInfo> {}

class _MockWownero extends Mock implements wow.Wownero {}

class _MockWowneroAccountList extends Mock implements wow.WowneroAccountList {}

class _MockWowneroWalletDetails extends Mock implements wow.WowneroWalletDetails {}

class _MockWowneroBalance extends Mock implements wow.WowneroBalance {}

class _DashboardViewModelProbe extends DashboardViewModelBase {
  _DashboardViewModelProbe({
    required super.balanceViewModel,
    required super.tradeMonitor,
    required super.appStore,
    required super.tradesStore,
    required super.tradeFilterStore,
    required super.orderFilterStore,
    required super.transactionFilterStore,
    required super.settingsStore,
    required super.yatStore,
    required super.ordersStore,
    required super.anonpayTransactionsStore,
    required super.payjoinTransactionsStore,
    required super.sharedPreferences,
    required super.keyService,
  });

  bool _loadRealCards = false;

  void enableRealCardLoading() => _loadRealCards = true;

  @override
  void loadFilterItems() {}

  @override
  Future<void> loadCardDesigns() => _loadRealCards ? super.loadCardDesigns() : Future<void>.value();

  @override
  Future<bool> isBackgroundSyncEnabled() async => false;

  @override
  Future<bool> isBatteryOptimizationEnabled() async => false;
}

void main() {
  late DatabaseFactory? originalDatabaseFactory;
  late Database? originalDatabase;
  late wow.Wownero? originalWownero;

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
    originalWownero = wow.wownero;
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
    wow.wownero = originalWownero;
    await sqlite.db?.close();
    sqlite.db = originalDatabase;
  });

  test("Wownero keeps every account card and maps the selected account", () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final sharedPreferences = await SharedPreferences.getInstance();
    final wallet = _MockWallet();
    final walletInfo = _MockWalletInfo();
    final transactionHistory = _MockTransactionHistory();
    final appStore = _MockAppStore();
    final settingsStore = _MockSettingsStore();
    final tradesStore = _MockTradesStore();
    final tradeMonitor = _MockTradeMonitor();
    final wowneroAdapter = _MockWownero();
    final accountList = _MockWowneroAccountList();
    final walletDetails = _MockWowneroWalletDetails();
    final wowneroBalance = _MockWowneroBalance();
    final accounts = ObservableList.of(<wow.Account>[
      wow.Account(id: 0, label: "Primary", balance: "1.0"),
      wow.Account(id: 1, label: "Savings", balance: "2.0"),
    ]);

    wow.wownero = wowneroAdapter;
    when(() => appStore.wallet).thenReturn(wallet);
    when(() => wallet.name).thenReturn("Wownero Wallet");
    when(() => wallet.id).thenReturn("wownero-wallet");
    when(() => wallet.type).thenReturn(WalletType.wownero);
    when(() => wallet.currency).thenReturn(CryptoCurrency.wow);
    when(() => wallet.walletInfo).thenReturn(walletInfo);
    when(() => walletInfo.internalId).thenReturn(42);
    when(() => wallet.transactionHistory).thenReturn(transactionHistory);
    when(() => transactionHistory.transactions)
        .thenReturn(ObservableMap<String, TransactionInfo>());
    when(() => wowneroAdapter.getAccountList(wallet)).thenReturn(accountList);
    when(() => accountList.accounts).thenReturn(accounts);
    when(() => wowneroAdapter.getCurrentAccount(wallet)).thenReturn(accounts[1]);
    when(() => wowneroAdapter.getWowneroWalletDetails(wallet)).thenReturn(walletDetails);
    when(() => walletDetails.account).thenReturn(accounts[1]);
    when(() => walletDetails.balance).thenReturn(wowneroBalance);
    when(() => settingsStore.mwebAlwaysScan).thenReturn(false);
    when(() => tradesStore.trades).thenReturn(const []);
    when(() => tradeMonitor.monitorActiveTrades(any())).thenReturn(null);

    final viewModel = _DashboardViewModelProbe(
      balanceViewModel: _MockBalanceViewModel(),
      tradeMonitor: tradeMonitor,
      appStore: appStore,
      tradesStore: tradesStore,
      tradeFilterStore: _MockTradeFilterStore(),
      orderFilterStore: _MockOrderFilterStore(),
      transactionFilterStore: _MockTransactionFilterStore(),
      settingsStore: settingsStore,
      yatStore: _MockYatStore(),
      ordersStore: _MockOrdersStore(),
      anonpayTransactionsStore: _MockAnonpayTransactionsStore(),
      payjoinTransactionsStore: _MockPayjoinTransactionsStore(),
      sharedPreferences: sharedPreferences,
      keyService: _MockKeyService(),
    );

    expect(viewModel.cardAccountIndices, <int>[0, 1]);
    expect(viewModel.currentCardAccountIndex, 1);

    viewModel.enableRealCardLoading();
    await viewModel.loadCardDesigns();

    expect(viewModel.cardOrder, <int, int>{0: 0, 1: 1});
    expect(viewModel.cardDesigns, hasLength(2));
    expect(viewModel.currentCardDesign, same(viewModel.cardDesigns[1]));
  });
}
