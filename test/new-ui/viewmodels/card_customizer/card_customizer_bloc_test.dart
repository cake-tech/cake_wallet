import "package:cake_wallet/new-ui/viewmodels/card_customizer/card_customizer_bloc.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/balance_card_style_settings.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/db/sqlite.dart" as sqlite;
import "package:flutter_test/flutter_test.dart";
import "package:mocktail/mocktail.dart";
import "package:sqflite_common_ffi/sqflite_ffi.dart";

import "../../../view_model/wallet_account_list/fake_account_wallet.dart";

void main() {
  late DatabaseFactory? originalDatabaseFactory;
  late Database? originalDatabase;
  late FakeAccountWallet wallet;

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

    final walletInfo = FakeWalletInfo();
    when(() => walletInfo.internalId).thenReturn(42);
    wallet = FakeAccountWallet(
      currency: CryptoCurrency.wow,
      walletInfo: walletInfo,
      currentAccountIndex: 3,
      accounts: [
        FakeWalletAccount(index: 0, label: "Primary", balance: Money.zero(CryptoCurrency.wow)),
        FakeWalletAccount(index: 3, label: "Savings", balance: Money.zero(CryptoCurrency.wow)),
      ],
    );
    when(() => wallet.hasNativeAccounts).thenReturn(true);
  });

  tearDown(() async {
    await sqlite.db?.close();
    sqlite.db = originalDatabase;
  });

  test("customization saves the selected account identity and name", () async {
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

    expect(wallet.account(3).label, "Long-term Savings");
    expect(wallet.account(0).label, "Primary");
    expect(wallet.saveCount, 1);

    final persisted = await BalanceCardStyleSettings.get(42, 3);
    expect(persisted, isNotNull);
    expect(await BalanceCardStyleSettings.get(42, -1), isNull);
  });
}
