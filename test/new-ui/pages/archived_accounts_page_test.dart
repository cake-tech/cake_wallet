import "dart:async";

import "package:cake_wallet/di.dart";
import "package:cake_wallet/entities/fiat_currency.dart";
import "package:cake_wallet/entities/preferences_key.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/locales/locale.dart";
import "package:cake_wallet/new-ui/pages/account_customizer.dart";
import "package:cake_wallet/new-ui/pages/account_education_page.dart";
import "package:cake_wallet/new-ui/pages/card_customizer.dart";
import "package:cake_wallet/new-ui/pages/hidden_accounts.dart";
import "package:cake_wallet/new-ui/viewmodels/card_customizer/card_customizer_bloc.dart";
import "package:cake_wallet/new-ui/widgets/coins_page/cards/balance_card.dart";
import "package:cake_wallet/new-ui/widgets/modern_button.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cake_wallet/themes/core/theme_store.dart";
import "package:cake_wallet/view_model/dashboard/balance_view_model.dart";
import "package:cake_wallet/view_model/dashboard/dashboard_view_model.dart";
import "package:cake_wallet/view_model/monero_account_list/account_list_item.dart";
import "package:cake_wallet/view_model/monero_account_list/monero_account_list_view_model.dart";
import "package:cw_core/balance.dart";
import "package:cw_core/balance_card_layout.dart";
import "package:cw_core/balance_card_style_settings.dart";
import "package:cw_core/card_design.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/db/sqlite.dart" as sqlite;
import "package:cw_core/sync_status.dart";
import "package:cw_core/transaction_history.dart";
import "package:cw_core/transaction_info.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mocktail/mocktail.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:sqflite_common_ffi/sqflite_ffi.dart";

class _MockDashboardViewModel extends Mock implements DashboardViewModel {}

class _MockBalanceViewModel extends Mock implements BalanceViewModel {}

class _MockAccountListViewModel extends Mock implements MoneroAccountListViewModel {}

class _MockWallet extends Mock
    implements WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo> {}

class _MockWalletInfo extends Mock implements WalletInfo {}

class _MockCardCustomizerBloc extends Mock implements CardCustomizerBloc {}

class _MockSettingsStore extends Mock implements SettingsStore {}

Future<void> _waitForArchivePage(WidgetTester tester) async {
  for (var attempt = 0; attempt < 50; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
    if (find.byType(CircularProgressIndicator).evaluate().isEmpty) {
      return;
    }
  }

  throw TestFailure("Archived accounts did not finish loading");
}

Future<void> _waitForTextToDisappear(WidgetTester tester, String text) async {
  for (var attempt = 0; attempt < 50; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 20));
    if (find.text(text).evaluate().isEmpty) {
      return;
    }
  }

  throw TestFailure("$text did not disappear");
}

Future<void> _pumpUntil(WidgetTester tester, bool Function() done) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 10));
    if (done()) {
      return;
    }
  }

  throw TestFailure("Timed out waiting for AccountCustomizer");
}

void main() {
  late bool registeredThemeStore;
  late DatabaseFactory? originalDatabaseFactory;
  late Database? originalDatabase;
  late _MockDashboardViewModel dashboardViewModel;
  late _MockBalanceViewModel balanceViewModel;
  late _MockAccountListViewModel accountListViewModel;
  late _MockWallet wallet;
  late _MockWalletInfo walletInfo;

  final fundedAccount = AccountListItem(id: 0, label: "Savings", balance: "1.25");
  final activeAccount = AccountListItem(id: 1, label: "Primary", balance: "0");
  final emptyAccount = AccountListItem(id: 2, label: "Travel", balance: "0");

  setUpAll(() {
    registerFallbackValue(DesignSaved());
    registerFallbackValue(AccountListItem(id: -1, label: "fallback"));

    registeredThemeStore = !getIt.isRegistered<ThemeStore>();
    if (registeredThemeStore) {
      getIt.registerSingleton(ThemeStore());
    }

    originalDatabaseFactory = databaseFactoryOrNull;
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDownAll(() async {
    databaseFactoryOrNull = originalDatabaseFactory;
    if (registeredThemeStore) {
      await getIt.unregister<ThemeStore>();
    }
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

    dashboardViewModel = _MockDashboardViewModel();
    balanceViewModel = _MockBalanceViewModel();
    accountListViewModel = _MockAccountListViewModel();
    wallet = _MockWallet();
    walletInfo = _MockWalletInfo();

    when(() => dashboardViewModel.balanceViewModel).thenReturn(balanceViewModel);
    when(() => dashboardViewModel.wallet).thenReturn(wallet);
    when(() => dashboardViewModel.loadCardDesigns()).thenAnswer((_) async {});
    when(() => balanceViewModel.isFiatDisabled).thenReturn(true);
    when(() => wallet.walletInfo).thenReturn(walletInfo);
    when(() => walletInfo.internalId).thenReturn(42);
    when(() => accountListViewModel.currency).thenReturn(CryptoCurrency.xmr);
    when(() => accountListViewModel.accounts).thenReturn([activeAccount]);
  });

  tearDown(() async {
    await sqlite.db?.close();
    sqlite.db = originalDatabase;
  });

  Future<void> hideAccount(int accountId, int order) => BalanceCardStyleSettings.fromCardDesign(
        walletInfoId: 42,
        accountIndex: accountId,
        cardOrder: order,
        design: CardDesign.gradientOnlyDesign,
        hidden: true,
      ).insert();

  Widget testApp(Widget home) => MaterialApp(
        localizationsDelegates: localizationDelegates,
        supportedLocales: S.delegate.supportedLocales,
        home: home,
      );

  testWidgets("empty archive explains where archived accounts will appear", (tester) async {
    await tester.pumpWidget(
      testApp(
        HiddenAccountsPage(
          accountListViewModel: accountListViewModel,
          dashboardViewModel: dashboardViewModel,
        ),
      ),
    );
    await _waitForArchivePage(tester);

    expect(find.text("Archived Accounts"), findsOneWidget);
    expect(find.text("No Archived Accounts"), findsOneWidget);
    expect(find.text("When you Archive an Account, it will show up here"), findsOneWidget);
  });

  testWidgets("archived accounts use the persisted hidden layout and Figma groups", (tester) async {
    when(() => accountListViewModel.accounts)
        .thenReturn([fundedAccount, activeAccount, emptyAccount]);
    await tester.runAsync(() async {
      await hideAccount(fundedAccount.id, 0);
      await hideAccount(emptyAccount.id, 1);
    });

    await tester.pumpWidget(
      testApp(
        HiddenAccountsPage(
          accountListViewModel: accountListViewModel,
          dashboardViewModel: dashboardViewModel,
        ),
      ),
    );
    await _waitForArchivePage(tester);

    expect(find.text("Funded accounts"), findsOneWidget);
    expect(find.text("Unarchive an account to access its funds"), findsOneWidget);
    expect(find.text("1. Savings"), findsOneWidget);
    expect(find.text("1.25 XMR"), findsOneWidget);
    expect(find.text("Empty Accounts"), findsOneWidget);
    expect(find.text("3. Travel"), findsOneWidget);
    expect(find.text("0 XMR"), findsOneWidget);
  });

  testWidgets("archived account fiat balance uses the current price and locale", (tester) async {
    final settingsStore = _MockSettingsStore();

    when(() => accountListViewModel.accounts).thenReturn([fundedAccount, activeAccount]);
    when(() => balanceViewModel.isFiatDisabled).thenReturn(false);
    when(() => balanceViewModel.price).thenReturn(20);
    when(() => dashboardViewModel.settingsStore).thenReturn(settingsStore);
    when(() => settingsStore.fiatCurrency).thenReturn(FiatCurrency.usd);
    when(() => settingsStore.languageCode).thenReturn("de_DE");
    await tester.runAsync(() => hideAccount(fundedAccount.id, 0));

    await tester.pumpWidget(
      testApp(
        HiddenAccountsPage(
          accountListViewModel: accountListViewModel,
          dashboardViewModel: dashboardViewModel,
        ),
      ),
    );
    await _waitForArchivePage(tester);

    expect(find.text("1.25 XMR"), findsOneWidget);
    expect(find.text("25,00 USD"), findsOneWidget);
  });

  testWidgets("AccountCustomizer shows education only until it has been seen", (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    var cardDesignLoads = 0;

    when(() => dashboardViewModel.sharedPreferences).thenReturn(preferences);
    when(() => dashboardViewModel.loadCardDesigns()).thenAnswer((_) async {
      cardDesignLoads++;
    });
    when(() => wallet.type).thenReturn(WalletType.monero);
    when(() => wallet.currency).thenReturn(CryptoCurrency.xmr);

    await tester.pumpWidget(
      testApp(
        AccountCustomizer(
          accountListViewModel: accountListViewModel,
          dashboardViewModel: dashboardViewModel,
        ),
      ),
    );
    await _pumpUntil(tester, () => find.byType(AccountEducationPage).evaluate().isNotEmpty);

    expect(find.byType(AccountEducationPage), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(AccountEducationPage),
        matching: find.bySemanticsLabel("Close"),
      ),
    );
    await tester.pumpAndSettle();
    expect(preferences.getBool(PreferencesKey.accountsEducationSeen), isTrue);

    final loadsBeforeFirstDispose = cardDesignLoads;
    await tester.pumpWidget(testApp(const SizedBox.shrink()));
    await _pumpUntil(tester, () => cardDesignLoads > loadsBeforeFirstDispose);

    await tester.pumpWidget(
      testApp(
        AccountCustomizer(
          accountListViewModel: accountListViewModel,
          dashboardViewModel: dashboardViewModel,
        ),
      ),
    );
    await _pumpUntil(tester, () => find.text("Add Account").evaluate().isNotEmpty);
    await tester.pumpAndSettle();

    expect(find.byType(AccountEducationPage), findsNothing);

    final loadsBeforeSecondDispose = cardDesignLoads;
    await tester.pumpWidget(testApp(const SizedBox.shrink()));
    await _pumpUntil(tester, () => cardDesignLoads > loadsBeforeSecondDispose);
  });

  testWidgets("unnamed archived accounts get the Figma display fallback", (tester) async {
    final unnamedAccount = AccountListItem(id: 4, label: "", balance: "0");
    when(() => accountListViewModel.accounts).thenReturn([activeAccount, unnamedAccount]);
    await tester.runAsync(() => hideAccount(unnamedAccount.id, 0));

    await tester.pumpWidget(
      testApp(
        HiddenAccountsPage(
          accountListViewModel: accountListViewModel,
          dashboardViewModel: dashboardViewModel,
        ),
      ),
    );
    await _waitForArchivePage(tester);

    expect(find.text("5. Unnamed Account"), findsOneWidget);
  });

  testWidgets("funded archival warning returns false on Cancel", (tester) async {
    bool? result;

    await tester.pumpWidget(
      testApp(
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await confirmAccountArchival(
                  context,
                  account: fundedAccount,
                  accountListViewModel: accountListViewModel,
                  dashboardViewModel: dashboardViewModel,
                );
              },
              child: const Text("Open archive warning"),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text("Open archive warning"));
    await tester.pumpAndSettle();

    expect(find.text("Are you sure you want to Archive this account?"), findsOneWidget);
    expect(find.text("This account has the following funds:"), findsOneWidget);
    expect(
      find.text("Before proceeding, it is recommended you move them to an account you will use"),
      findsOneWidget,
    );
    expect(
      find.text(
        "Archiving an account does not delete any funds or activity. You can reverse this action",
      ),
      findsOneWidget,
    );

    await tester.tap(find.text("Cancel"));
    await tester.pumpAndSettle();
    expect(result, isFalse);
  });

  testWidgets("empty archival disclaimer returns true on Continue", (tester) async {
    bool? result;

    await tester.pumpWidget(
      testApp(
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await confirmAccountArchival(
                  context,
                  account: emptyAccount,
                  accountListViewModel: accountListViewModel,
                  dashboardViewModel: dashboardViewModel,
                );
              },
              child: const Text("Open archive warning"),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text("Open archive warning"));
    await tester.pumpAndSettle();

    expect(find.text("Archive Account"), findsOneWidget);
    expect(find.text("3. Travel"), findsOneWidget);
    expect(
      find.text(
        "This action won’t delete the account or its past activity, but only hide it inside Cake Wallet",
      ),
      findsOneWidget,
    );
    expect(find.text("You can reverse this action from Accounts settings"), findsOneWidget);

    await tester.tap(find.text("Continue"));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  testWidgets("unarchive helper uses funded copy and returns true", (tester) async {
    bool? result;

    await tester.pumpWidget(
      testApp(
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await confirmAccountUnarchival(
                  context,
                  account: fundedAccount,
                  accountListViewModel: accountListViewModel,
                  dashboardViewModel: dashboardViewModel,
                );
              },
              child: const Text("Open unarchive warning"),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text("Open unarchive warning"));
    await tester.pumpAndSettle();

    expect(find.text("Unarchive this account?"), findsOneWidget);
    expect(
      find.text("This account will show up again on your wallet, letting you access your funds"),
      findsOneWidget,
    );

    await tester.tap(find.text("Continue"));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  testWidgets("unarchiving uses the latest account state for confirmation and selection",
      (tester) async {
    when(() => accountListViewModel.accounts).thenReturn([emptyAccount, activeAccount]);
    await tester.runAsync(() => hideAccount(emptyAccount.id, 0));

    await tester.pumpWidget(
      testApp(
        HiddenAccountsPage(
          accountListViewModel: accountListViewModel,
          dashboardViewModel: dashboardViewModel,
        ),
      ),
    );
    await _waitForArchivePage(tester);

    final accountForConfirmation =
        AccountListItem(id: emptyAccount.id, label: emptyAccount.label, balance: "1.5");
    when(() => accountListViewModel.accounts).thenReturn([accountForConfirmation, activeAccount]);
    await tester.tap(find.text("3. Travel"));
    await tester.pumpAndSettle();

    expect(
      find.text("This account will show up again on your wallet, letting you access your funds"),
      findsOneWidget,
    );
    expect(find.text("1.5 XMR"), findsOneWidget);

    final latestAccount = AccountListItem(id: emptyAccount.id, label: "Updated", balance: "2.5");
    when(() => accountListViewModel.accounts).thenReturn([latestAccount, activeAccount]);
    await tester.tap(find.text("Continue"));
    await tester.pump();
    await _waitForTextToDisappear(tester, "3. Travel");

    final setting = await tester.runAsync(
      () => BalanceCardStyleSettings.get(42, emptyAccount.id),
    );
    final settings = await tester.runAsync(() => BalanceCardStyleSettings.getAll(42));
    final layout = BalanceCardLayout.resolve(
      accountIndices: [emptyAccount.id, activeAccount.id],
      settings: settings!,
    );

    expect(setting?.hidden, isFalse);
    expect(layout.hidden, isEmpty);
    expect(layout.visible, contains(emptyAccount.id));
    verify(() => accountListViewModel.select(latestAccount)).called(1);
    verify(() => dashboardViewModel.loadCardDesigns()).called(1);
    expect(find.text("3. Travel"), findsNothing);
    expect(find.text("No Archived Accounts"), findsOneWidget);
  });

  testWidgets("archive flow survives dismissal and protects the final visible account",
      (tester) async {
    final remainingAccount = AccountListItem(id: 0, label: "Primary", balance: "0");
    final archivedAccount = AccountListItem(
      id: 1,
      label: "Savings",
      balance: "0",
      isSelected: true,
    );
    final bloc = _MockCardCustomizerBloc();
    final settingsStore = _MockSettingsStore();
    final states = StreamController<CardCustomizerState>.broadcast();
    final events = <Type>[];
    final selections = <int>[];
    final canHideValues = <bool>[];
    final finishArchiveReload = Completer<void>();
    var canHide = false;
    var cardDesignLoads = 0;
    var pauseCardDesignLoad = false;

    SharedPreferences.setMockInitialValues(
      <String, Object>{PreferencesKey.accountsEducationSeen: true},
    );
    final preferences = await SharedPreferences.getInstance();
    var customizerState = CardCustomizerInitial(
      0,
      0,
      const <CardDesign>[CardDesign.gradientOnlyDesign],
      const <Gradient>[CardDesign.gradientBlue],
      "Savings",
      archivedAccount.id,
      false,
      1,
    );
    final savedState = CardCustomizerSaved(
      0,
      0,
      const <CardDesign>[CardDesign.gradientOnlyDesign],
      const <Gradient>[CardDesign.gradientBlue],
      "Savings",
      archivedAccount.id,
      false,
      1,
    );

    var accounts = <AccountListItem>[remainingAccount, archivedAccount];
    when(() => accountListViewModel.accounts).thenAnswer((_) => accounts);
    when(() => accountListViewModel.select(any())).thenAnswer((invocation) {
      selections.add((invocation.positionalArguments.single as AccountListItem).id);
    });
    when(() => dashboardViewModel.sharedPreferences).thenReturn(preferences);
    when(() => dashboardViewModel.status).thenReturn(SyncedSyncStatus());
    when(() => dashboardViewModel.settingsStore).thenReturn(settingsStore);
    when(() => dashboardViewModel.loadCardDesigns()).thenAnswer((_) async {
      cardDesignLoads++;
      if (pauseCardDesignLoad) {
        await finishArchiveReload.future;
      }
    });
    when(() => balanceViewModel.isFiatDisabled).thenReturn(false);
    when(() => balanceViewModel.price).thenReturn(20);
    when(() => settingsStore.fiatCurrency).thenReturn(FiatCurrency.usd);
    when(() => settingsStore.languageCode).thenReturn("de_DE");
    when(() => wallet.type).thenReturn(WalletType.monero);
    when(() => wallet.currency).thenReturn(CryptoCurrency.xmr);
    when(() => bloc.state).thenAnswer((_) => customizerState);
    when(() => bloc.stream).thenAnswer((_) => states.stream);
    when(() => bloc.canHide).thenAnswer((_) => canHide);
    when(() => bloc.add(any())).thenAnswer((invocation) {
      final event = invocation.positionalArguments.single as CardCustomizerEvent;
      if (event is AccountNameChanged) {
        customizerState = customizerState.copyWith(accountName: event.newAccountName);
        return;
      }
      events.add(event.runtimeType);

      if (event is DesignSaved) {
        scheduleMicrotask(() => states.add(savedState));
      } else if (event is AccountHidden) {
        // Simulate AccountHidden's persisted output so AccountCustomizer reloads visible cards.
        scheduleMicrotask(() {
          unawaited(
            BalanceCardStyleSettings.fromCardDesign(
              walletInfoId: 42,
              accountIndex: archivedAccount.id,
              cardOrder: 1,
              design: CardDesign.gradientOnlyDesign,
              hidden: true,
            ).insert().then((_) => states.add(savedState)),
          );
        });
      }
    });

    var scopeOpen = true;
    getIt.pushNewScope();
    addTearDown(() async {
      if (!finishArchiveReload.isCompleted) {
        finishArchiveReload.complete();
      }
      if (!states.isClosed) {
        await states.close();
      }
      if (scopeOpen) {
        await getIt.popScope();
      }
    });
    getIt.registerFactoryParam<CardCustomizerBloc, CardCustomizerBlocParams, void>(
      (params, _) {
        canHideValues.add(canHide = params.canHide);
        return bloc;
      },
    );

    await tester.pumpWidget(
      testApp(
        Scaffold(
          body: AccountCustomizer(
            accountListViewModel: accountListViewModel,
            dashboardViewModel: dashboardViewModel,
          ),
        ),
      ),
    );
    await _pumpUntil(tester, () => find.text("Add Account").evaluate().isNotEmpty);

    ModernButton archiveButton() => tester.widget<ModernButton>(
          find.ancestor(
            of: find.byIcon(Icons.inventory_2_outlined),
            matching: find.byType(ModernButton),
          ),
        );

    expect(archiveButton().backgroundColor, isNull);
    expect(archiveButton().iconColor, isNull);

    final frontCard = tester
        .widgetList<BalanceCard>(find.byType(BalanceCard))
        .singleWhere((card) => card.onCustomizeTapped != null);
    expect(frontCard.fiatBalance, "USD 0,00");
    frontCard.onCustomizeTapped!();
    await tester.pumpAndSettle();
    expect(find.byType(CardCustomizer), findsOneWidget);
    expect(canHideValues, <bool>[true]);
    expect(find.text("Archive Account"), findsOneWidget);

    await tester.enterText(find.byType(TextField), "Long-term Savings");
    await tester.ensureVisible(find.text("Archive Account"));
    await tester.tap(find.text("Archive Account"));
    await tester.pumpAndSettle();
    expect(find.text("2. Long-term Savings"), findsOneWidget);

    await tester.tap(find.text("Cancel"));
    await tester.pumpAndSettle();
    accounts = [
      remainingAccount,
      AccountListItem(
        id: archivedAccount.id,
        label: archivedAccount.label,
        balance: "2.5",
        isSelected: true,
      ),
    ];
    await tester.tap(find.text("Archive Account"));
    await tester.pumpAndSettle();
    expect(find.text("This account has the following funds:"), findsOneWidget);
    expect(find.text("2.5 XMR"), findsOneWidget);

    final loadsBeforeArchive = cardDesignLoads;
    pauseCardDesignLoad = true;
    await tester.tap(find.text("Continue"));
    await tester.pump();
    await _pumpUntil(
      tester,
      () => events.length == 2 && selections.length == 2 && cardDesignLoads > loadsBeforeArchive,
    );

    expect(events, <Type>[DesignSaved, AccountHidden]);
    expect(selections, <int>[archivedAccount.id, remainingAccount.id]);
    await tester.pumpWidget(testApp(const SizedBox.shrink()));
    pauseCardDesignLoad = false;
    finishArchiveReload.complete();
    await tester.pump();
    final archivedSetting = await tester.runAsync(() async {
      // Queue the final read behind both disposal writes from the unfixed flow.
      await BalanceCardStyleSettings.getAll(42);
      await BalanceCardStyleSettings.getAll(42);
      return BalanceCardStyleSettings.get(42, archivedAccount.id);
    });
    expect(archivedSetting?.hidden, isTrue);
    expect(selections, <int>[archivedAccount.id, remainingAccount.id]);

    await tester.pumpWidget(
      testApp(
        Scaffold(
          body: AccountCustomizer(
            accountListViewModel: accountListViewModel,
            dashboardViewModel: dashboardViewModel,
          ),
        ),
      ),
    );
    await _pumpUntil(tester, () => find.text("Add Account").evaluate().isNotEmpty);

    final colorScheme = Theme.of(tester.element(find.byType(AccountCustomizer))).colorScheme;
    expect(archiveButton().backgroundColor, colorScheme.primary);
    expect(archiveButton().iconColor, colorScheme.onPrimary);

    final remainingFrontCard = tester
        .widgetList<BalanceCard>(find.byType(BalanceCard))
        .singleWhere((card) => card.onCustomizeTapped != null);
    remainingFrontCard.onCustomizeTapped!();
    await tester.pumpAndSettle();

    expect(canHideValues, <bool>[true, false]);
    expect(find.text("Archive Account"), findsNothing);

    Navigator.of(tester.element(find.byType(CardCustomizer))).pop(false);
    await tester.pump();
    await _pumpUntil(tester, () => events.length == 3 && selections.length == 3);
    expect(events.last, DesignSaved);
    expect(selections.last, remainingAccount.id);

    final loadsBeforeDispose = cardDesignLoads;
    await tester.pumpWidget(testApp(const SizedBox.shrink()));
    await _pumpUntil(tester, () => cardDesignLoads > loadsBeforeDispose);
    await states.close();
    await getIt.popScope();
    scopeOpen = false;
  });
}
