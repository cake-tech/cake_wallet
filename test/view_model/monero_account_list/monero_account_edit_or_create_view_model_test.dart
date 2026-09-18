import "package:cake_wallet/core/execution_state.dart";
import "package:cake_wallet/monero/monero.dart" as xmr;
import "package:cake_wallet/view_model/monero_account_list/monero_account_edit_or_create_view_model.dart";
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
import "package:mobx/mobx.dart" show ObservableList;
import "package:mocktail/mocktail.dart";
import "package:sqflite_common_ffi/sqflite_ffi.dart";

class _MockWallet extends Mock
    implements WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo> {}

class _MockWalletInfo extends Mock implements WalletInfo {}

class _MockMoneroAccountList extends Mock implements xmr.MoneroAccountList {}

class _MockWowneroAccountList extends Mock implements wow.WowneroAccountList {}

void main() {
  late DatabaseFactory? originalDatabaseFactory;
  late Database? originalDatabase;
  late _MockWallet wallet;
  late _MockWalletInfo walletInfo;

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
        hidden BOOLEAN DEFAULT FALSE,
        useSpecialDesign BOOLEAN DEFAULT FALSE,
        backgroundImagePath TEXT DEFAULT "",
        iconStyleIndex INTEGER DEFAULT 0,
        isGradientOnly BOOLEAN DEFAULT FALSE,
        cardOrder INTEGER DEFAULT 0,
        PRIMARY KEY (walletInfoId, accountIndex)
      )
    """);

    wallet = _MockWallet();
    walletInfo = _MockWalletInfo();
    when(() => wallet.walletInfo).thenReturn(walletInfo);
    when(() => walletInfo.internalId).thenReturn(42);
    when(() => wallet.save()).thenAnswer((_) async {});
  });

  tearDown(() async {
    await sqlite.db?.close();
    sqlite.db = originalDatabase;
  });

  test("creates a Wownero account and stores its card design at the next Wownero index", () async {
    final accountList = _MockWowneroAccountList();
    final accounts = ObservableList<wow.Account>.of([
      wow.Account(id: 0, label: "Primary"),
      wow.Account(id: 1, label: "Savings"),
    ]);
    when(() => wallet.type).thenReturn(WalletType.wownero);
    when(() => wallet.currency).thenReturn(CryptoCurrency.wow);
    when(() => accountList.accounts).thenReturn(accounts);
    when(() => accountList.addAccount(wallet, label: "Spending")).thenAnswer((_) async {
      accounts.add(wow.Account(id: 2, label: "Spending"));
    });

    final viewModel = MoneroAccountEditOrCreateViewModel(
      null,
      accountList,
      wallet: wallet,
    )..label = "Spending";

    await viewModel.save();

    expect(viewModel.state, isA<ExecutedSuccessfullyState>());
    verify(() => accountList.addAccount(wallet, label: "Spending")).called(1);
    verify(() => wallet.save()).called(1);

    final cardDesign = await BalanceCardStyleSettings.get(42, 2);
    expect(cardDesign, isNotNull);
    expect(cardDesign!.accountIndex, 2);
    expect(cardDesign.cardOrder, 2);
  });

  test("creates a Monero account and stores its card design at the next Monero index", () async {
    final accountList = _MockMoneroAccountList();
    final accounts = ObservableList<xmr.Account>.of([
      xmr.Account(id: 0, label: "Primary"),
    ]);
    when(() => wallet.type).thenReturn(WalletType.monero);
    when(() => wallet.currency).thenReturn(CryptoCurrency.xmr);
    when(() => accountList.accounts).thenReturn(accounts);
    when(() => accountList.addAccount(wallet, label: "Savings")).thenAnswer((_) async {
      accounts.add(xmr.Account(id: 1, label: "Savings"));
    });

    final viewModel = MoneroAccountEditOrCreateViewModel(
      accountList,
      null,
      wallet: wallet,
    )..label = "Savings";

    await viewModel.save();

    expect(viewModel.state, isA<ExecutedSuccessfullyState>());
    verify(() => accountList.addAccount(wallet, label: "Savings")).called(1);
    verify(() => wallet.save()).called(1);

    final cardDesign = await BalanceCardStyleSettings.get(42, 1);
    expect(cardDesign, isNotNull);
    expect(cardDesign!.accountIndex, 1);
    expect(cardDesign.cardOrder, 1);
  });
}
