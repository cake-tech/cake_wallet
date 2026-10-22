import "package:cake_wallet/core/execution_state.dart";
import "package:cake_wallet/view_model/wallet_account_list/account_edit_or_create_view_model.dart";
import "package:cake_wallet/view_model/wallet_account_list/account_list_item.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/balance_card_style_settings.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/db/sqlite.dart" as sqlite;
import "package:flutter_test/flutter_test.dart";
import "package:mocktail/mocktail.dart";
import "package:sqflite_common_ffi/sqflite_ffi.dart";

import "fake_account_wallet.dart";

void main() {
  late DatabaseFactory? originalDatabaseFactory;
  late Database? originalDatabase;
  late FakeWalletInfo walletInfo;

  FakeAccountWallet createWallet({CryptoCurrency currency = CryptoCurrency.xmr}) =>
      FakeAccountWallet(
        currency: currency,
        walletInfo: walletInfo,
        accounts: [
          FakeWalletAccount(index: 0, label: "Primary", balance: Money.zero(currency)),
          FakeWalletAccount(index: 1, label: "Savings", balance: Money.zero(currency)),
        ],
      );

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

    walletInfo = FakeWalletInfo();
    when(() => walletInfo.internalId).thenReturn(42);
  });

  tearDown(() async {
    await sqlite.db?.close();
    sqlite.db = originalDatabase;
  });

  test("creates an account, selects it and stores its card design", () async {
    final wallet = createWallet();
    final viewModel = WalletAccountEditOrCreateViewModel(wallet)..label = "Spending";

    expect(viewModel.isEdit, isFalse);
    await viewModel.save();

    expect(viewModel.state, isA<ExecutedSuccessfullyState>());
    expect(wallet.walletAccounts.map((account) => account.label), ["Primary", "Savings", "Spending"]);
    expect(wallet.currentAccountIndex, 2);
    expect(wallet.saveCount, 1);

    final cardDesign = await BalanceCardStyleSettings.get(42, 2);
    expect(cardDesign, isNotNull);
    expect(cardDesign!.accountIndex, 2);
    expect(cardDesign.cardOrder, 2);
  });

  test("creates an account without a card design when the currency has none", () async {
    final wallet = createWallet(currency: CryptoCurrency.usdt);
    final viewModel = WalletAccountEditOrCreateViewModel(wallet)..label = "Spending";

    await viewModel.save();

    expect(viewModel.state, isA<ExecutedSuccessfullyState>());
    expect(wallet.currentAccountIndex, 2);
    expect(await BalanceCardStyleSettings.get(42, 2), isNull);
  });

  test("renames an existing account without creating or switching", () async {
    final wallet = createWallet();
    final account = AccountListItem(id: 1, label: "Savings", balance: Money.zero(CryptoCurrency.xmr));
    final viewModel = WalletAccountEditOrCreateViewModel(wallet, account: account);

    expect(viewModel.isEdit, isTrue);
    expect(viewModel.label, "Savings");

    viewModel.label = "Long-term";
    await viewModel.save();

    expect(viewModel.state, isA<ExecutedSuccessfullyState>());
    expect(wallet.account(1).label, "Long-term");
    expect(wallet.walletAccounts, hasLength(2));
    expect(wallet.currentAccountIndex, 0);
    expect(wallet.saveCount, 1);
    expect(await BalanceCardStyleSettings.get(42, 1), isNull);
  });

  test("reports a failure when the wallet does not support accounts", () async {
    final viewModel = WalletAccountEditOrCreateViewModel(
      SingleAccountWallet(Money.zero(CryptoCurrency.ltc)),
    )..label = "Spending";

    await viewModel.save();

    expect(viewModel.state, isA<FailureState>());
  });
}
