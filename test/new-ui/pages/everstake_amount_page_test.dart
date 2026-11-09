import "dart:async";

import "package:cake_wallet/core/auth_service.dart";
import "package:cake_wallet/core/everstake/ethereum_pool.dart";
import "package:cake_wallet/core/everstake/everstake_service.dart";
import "package:cake_wallet/core/everstake/models.dart";
import "package:cake_wallet/entities/balance_display_mode.dart";
import "package:cake_wallet/entities/bitcoin_amount_display_mode.dart";
import "package:cake_wallet/entities/fiat_currency.dart";
import "package:cake_wallet/evm/evm.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/locales/locale.dart";
import "package:cake_wallet/new-ui/pages/everstake/everstake_amount_page.dart";
import "package:cake_wallet/new-ui/viewmodels/everstake/everstake_bloc.dart";
import "package:cake_wallet/new-ui/viewmodels/fiat_rate/fiat_rate_cubit.dart";
import "package:cake_wallet/new-ui/widgets/money/money_settings_cubit.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cw_core/amount/exchange_rate.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/balance.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/transaction_history.dart";
import "package:cw_core/transaction_info.dart";
import "package:cw_core/wallet_addresses.dart";
import "package:cw_core/wallet_base.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mobx/mobx.dart" show ObservableMap;
import "package:mocktail/mocktail.dart";
import "package:web3dart/json_rpc.dart";

class _MockWallet extends Mock
    implements WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo> {}

class _MockWalletAddresses extends Mock implements WalletAddresses {}

class _MockSettingsStore extends Mock implements SettingsStore {}

class _MockEverstakeService extends Mock implements EverstakeService {}

class _MockEVM extends Mock implements EVM {}

class _MockAuthService extends Mock implements AuthService {}

class _FakeBuildContext extends Fake implements BuildContext {}

class _FakeMoneySettingsCubit extends Cubit<MoneySettingsState> implements MoneySettingsCubit {
  _FakeMoneySettingsCubit()
      : super(
          const MoneySettingsState(
            bitcoinAmountDisplayMode: BitcoinAmountDisplayMode.bitcoin,
            displayMode: BalanceDisplayMode.fullBalance,
          ),
        );
}

class _FakeFiatRateCubit extends Cubit<ExchangeRate?> implements FiatRateCubit {
  _FakeFiatRateCubit(super.rate);
}

class _Balance extends Balance {
  _Balance(Money available) : super(available, Money.zero(available.currency));
}

const _staker = "0x15273714bdfed50e922c4cdd35ed50291780b392";

Money _eth(String amount) => Money.parse(amount, CryptoCurrency.eth);

void main() {
  late _MockEverstakeService service;
  late _MockAuthService authService;
  late _MockSettingsStore settingsStore;
  late List<EverstakeEthereumCall> ethCalls;
  late EverstakeEthereumPool pool;
  late EverstakeBloc bloc;

  final usdRate = ExchangeRate(
    base: CryptoCurrency.eth,
    quote: Money.parse("2000", FiatCurrency.usd),
  );

  setUpAll(() {
    registerFallbackValue(_FakeBuildContext());
  });

  void authenticate({required bool authenticated}) => when(
        () => authService.authenticateAction(
          any(),
          onAuthSuccess: any(named: "onAuthSuccess"),
          conditionToDetermineIfToUse2FA: any(named: "conditionToDetermineIfToUse2FA"),
        ),
      ).thenAnswer(
        (invocation) async =>
            Function.apply(invocation.namedArguments[#onAuthSuccess] as Function, [authenticated]),
      );

  setUp(() {
    service = _MockEverstakeService();
    settingsStore = _MockSettingsStore();
    authService = _MockAuthService();
    when(() => authService.settingsStore).thenReturn(settingsStore);
    when(() => settingsStore.shouldRequireTOTP2FAForSendsToNonContact).thenReturn(false);
    when(() => settingsStore.shouldRequireTOTP2FAForSendsToInternalWallets).thenReturn(false);
    authenticate(authenticated: true);

    final wallet = _MockWallet();
    final addresses = _MockWalletAddresses();
    when(() => wallet.walletAddresses).thenReturn(addresses);
    when(() => addresses.address).thenReturn(_staker);
    when(() => wallet.chainId).thenReturn(1);
    when(() => wallet.balance)
        .thenReturn(ObservableMap.of({CryptoCurrency.eth: _Balance(_eth("1"))}));

    when(() => service.getEthereumMinStakeAmount()).thenAnswer((_) async => _eth("0.01"));
    when(() => service.getEthereumFee()).thenAnswer((_) async => 0.1);
    when(() => service.getEthereumUserBalances(any())).thenAnswer(
      (_) async => EverstakeEthereumUserBalances.fromJson({
        "pendingBalanceOf": "0",
        "pendingDepositedBalanceOf": "0",
        "autocompoundBalanceOf": "0.123456789012345678",
      }),
    );
    when(() => service.getEthereumRestakedRewards(any())).thenAnswer((_) async => _eth("0.003"));
    when(() => service.getEthereumWithdrawRequest(any())).thenAnswer(
      (_) async =>
          EverstakeEthereumWithdrawRequest.fromJson({"requested": "0", "readyForClaim": "0"}),
    );
    when(() => service.getEthereumApr()).thenAnswer((_) async => 0.026);
    when(() => service.getEthereumValidatorQueue()).thenAnswer(
      (_) async => EverstakeEthereumValidatorQueue.fromJson({
        "validator_activation_time": 1637220,
        "validator_adding_delay": 57600,
        "validator_exit_time": 167700,
        "validator_withdraw_time": 720900,
      }),
    );
    when(() => service.getEthereumTotalRewards(any())).thenAnswer((_) async => _eth("0.003"));

    ethCalls = [];
    // Stops the flow before signing; only the requested amount matters here.
    pool = EverstakeEthereumPool((call) {
      ethCalls.add(call);
      return Future.error(const RPCError(3, "execution reverted", null));
    });
    bloc = EverstakeBloc(
      wallet: wallet,
      settingsStore: settingsStore,
      evm: _MockEVM(),
      service: service,
      pool: pool,
    );
  });

  tearDown(() {
    unawaited(bloc.close());
  });

  Future<void> openAmountPage(WidgetTester tester, EverstakeAmountMode mode) async {
    await tester.pump();
    expect(bloc.state, isA<EverstakeReady>());

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<MoneySettingsCubit>(create: (_) => _FakeMoneySettingsCubit()),
          BlocProvider<FiatRateCubit>(create: (_) => _FakeFiatRateCubit(usdRate)),
          BlocProvider.value(value: bloc),
        ],
        child: MaterialApp(
          localizationsDelegates: localizationDelegates,
          supportedLocales: S.delegate.supportedLocales,
          home: Scaffold(body: EverstakeAmountPage(mode: mode, authService: authService)),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets("stakes the ETH a fiat amount buys", (tester) async {
    await openAmountPage(tester, EverstakeAmountMode.deposit);

    await tester.enterText(find.byType(TextFormField), "100");
    await tester.pump();
    expect(find.text("0.05 ETH"), findsOneWidget);

    await tester.tap(find.text("Continue"));
    await tester.pump();

    expect(ethCalls, [pool.stakeCall(_eth("0.05"))]);
  });

  testWidgets("All withdraws the exact stake rather than its rounded fiat value", (tester) async {
    await openAmountPage(tester, EverstakeAmountMode.withdraw);

    await tester.tap(find.text("All"));
    await tester.pump();
    expect(find.text("246.91"), findsOneWidget);

    await tester.tap(find.text("Continue"));
    await tester.pump();
    // All re-reads the stake first, and the bloc runs outside the fake async zone
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));

    expect(ethCalls, [pool.unstakeCall(_eth("0.123456789012345678"))]);
  });

  testWidgets("All withdraws the stake as it is at Continue, not when the page opened",
      (tester) async {
    await openAmountPage(tester, EverstakeAmountMode.withdraw);
    when(() => service.getEthereumUserBalances(any())).thenAnswer(
      (_) async => EverstakeEthereumUserBalances.fromJson({
        "pendingBalanceOf": "0",
        "pendingDepositedBalanceOf": "0",
        "autocompoundBalanceOf": "0.123456789012345999",
      }),
    );

    await tester.tap(find.text("All"));
    await tester.pump();
    await tester.tap(find.text("Continue"));
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));

    expect(ethCalls, [pool.unstakeCall(_eth("0.123456789012345999"))]);
  });

  testWidgets("All on a pending stake withdraws that pending stake", (tester) async {
    when(() => service.getEthereumUserBalances(any())).thenAnswer(
      (_) async => EverstakeEthereumUserBalances.fromJson({
        "pendingBalanceOf": "0.05",
        "pendingDepositedBalanceOf": "0",
        "autocompoundBalanceOf": "0.123456789012345678",
      }),
    );
    bloc.add(const StakingDataRequested());
    await tester.runAsync(() => bloc.stream.firstWhere((state) => state is EverstakeReady));
    await openAmountPage(tester, EverstakeAmountMode.withdraw);

    await tester.tap(find.text("All"));
    await tester.pump();
    await tester.tap(find.text("Continue"));
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));

    expect(ethCalls, [pool.unstakePendingCall(_eth("0.05"))]);
  });

  testWidgets("asks for 2FA before a deposit and stakes nothing without it", (tester) async {
    when(() => settingsStore.shouldRequireTOTP2FAForSendsToNonContact).thenReturn(true);
    authenticate(authenticated: false);
    await openAmountPage(tester, EverstakeAmountMode.deposit);

    await tester.enterText(find.byType(TextFormField), "100");
    await tester.pump();
    await tester.tap(find.text("Continue"));
    await tester.pump();

    verify(
      () => authService.authenticateAction(
        any(),
        onAuthSuccess: any(named: "onAuthSuccess"),
        conditionToDetermineIfToUse2FA: true,
      ),
    ).called(1);
    expect(ethCalls, isEmpty);
  });
}
