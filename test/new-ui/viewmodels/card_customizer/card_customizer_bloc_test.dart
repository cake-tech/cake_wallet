import "package:cake_wallet/new-ui/viewmodels/card_customizer/card_customizer_bloc.dart";
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
import "package:mocktail/mocktail.dart";
import "package:sqflite_common_ffi/sqflite_ffi.dart";

class _MockWallet extends Mock
    implements WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo> {}

class _MockWalletInfo extends Mock implements WalletInfo {}

class _MockWownero extends Mock implements wow.Wownero {}

class _MockWowneroAccountList extends Mock implements wow.WowneroAccountList {}

void main() {
  late DatabaseFactory? originalDatabaseFactory;
  late Database? originalDatabase;
  late wow.Wownero? originalWownero;
  late _MockWallet wallet;
  late _MockWownero wowneroAdapter;
  late _MockWowneroAccountList accountList;

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

    wallet = _MockWallet();
    final walletInfo = _MockWalletInfo();
    wowneroAdapter = _MockWownero();
    accountList = _MockWowneroAccountList();
    wow.wownero = wowneroAdapter;

    when(() => wallet.type).thenReturn(WalletType.wownero);
    when(() => wallet.currency).thenReturn(CryptoCurrency.wow);
    when(() => wallet.walletInfo).thenReturn(walletInfo);
    when(() => walletInfo.internalId).thenReturn(42);
    when(() => wallet.save()).thenAnswer((_) async {});
    when(() => wowneroAdapter.getCurrentAccount(wallet))
        .thenReturn(wow.Account(id: 3, label: "Savings", balance: "2.0"));
    when(() => wowneroAdapter.getAccountList(wallet)).thenReturn(accountList);
    when(
      () => accountList.setLabelAccount(
        wallet,
        accountIndex: any(named: "accountIndex"),
        label: any(named: "label"),
      ),
    ).thenAnswer((_) async {});
  });

  tearDown(() async {
    wow.wownero = originalWownero;
    await sqlite.db?.close();
    sqlite.db = originalDatabase;
  });

  test("Wownero customization saves the selected account identity and name", () async {
    final bloc = CardCustomizerBloc(wallet);
    addTearDown(bloc.close);

    final initial = await bloc.stream.firstWhere((state) => state is CardCustomizerInitial);
    expect(initial.accountIndex, 3);
    expect(initial.accountName, "Savings");
    expect(bloc.canHide, isFalse);

    final renamed = bloc.stream.firstWhere((state) => state.accountName == "Long-term Savings");
    bloc.add(AccountNameChanged("Long-term Savings"));
    await renamed;

    final saved = bloc.stream.firstWhere((state) => state is CardCustomizerSaved);
    bloc.add(DesignSaved());
    await saved;

    verify(
      () => accountList.setLabelAccount(
        wallet,
        accountIndex: 3,
        label: "Long-term Savings",
      ),
    ).called(1);
    verify(() => wallet.save()).called(1);

    final persisted = await BalanceCardStyleSettings.get(42, 3);
    expect(persisted, isNotNull);
    expect(await BalanceCardStyleSettings.get(42, -1), isNull);
  });
}
