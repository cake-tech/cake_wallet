import "package:cake_wallet/core/everstake/ethereum_transaction_validator.dart";
import "package:cake_wallet/core/everstake/everstake_service.dart";
import "package:cake_wallet/core/everstake/exceptions.dart";
import "package:cake_wallet/core/everstake/models.dart";
import "package:cake_wallet/evm/evm.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/viewmodels/everstake/everstake_bloc.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/balance.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/pending_transaction.dart";
import "package:cw_core/transaction_direction.dart";
import "package:cw_core/transaction_history.dart";
import "package:cw_core/transaction_info.dart";
import "package:cw_core/wallet_addresses.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mobx/mobx.dart" show ObservableMap, runInAction;
import "package:mocktail/mocktail.dart";
import "package:shared_preferences/shared_preferences.dart";

class _MockWallet extends Mock
    implements WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo> {}

class _MockWalletAddresses extends Mock implements WalletAddresses {}

class _MockSettingsStore extends Mock implements SettingsStore {}

class _MockEVM extends Mock implements EVM {}

class _MockEverstakeService extends Mock implements EverstakeService {}

class _MockPendingTransaction extends Mock implements PendingTransaction {}

class _MockTransactionHistory extends Mock implements TransactionHistoryBase<TransactionInfo> {}

class _MockTransactionInfo extends Mock implements TransactionInfo {}

class _Balance extends Balance {
  _Balance(Money available) : super(available, Money.zero(available.currency));
}

// A stake built by wallet-sdk-api.everstake.com for a real mainnet staker.
const _staker = "0x15273714bdfed50e922c4cdd35ed50291780b392";
const _stake = <String, dynamic>{
  "from": _staker,
  "to": "0xD523794C879D9eC028960a231F866758e405bE34",
  "value": 0.12345678901234568,
  "gasLimit": 479948,
  "data": "0x3a29dbae0000000000000000000000000000000000000000000000000000000000000000",
};

Money _eth(String amount) => Money.parse(amount, CryptoCurrency.eth);

EverstakeEthereumUserBalances _balances({
  String pending = "0",
  String pendingDeposited = "0",
  String autocompound = "0",
}) =>
    EverstakeEthereumUserBalances.fromJson({
      "pendingBalanceOf": pending,
      "pendingDepositedBalanceOf": pendingDeposited,
      "autocompoundBalanceOf": autocompound,
    });

void main() {
  late _MockWallet wallet;
  late ObservableMap<CryptoCurrency, Balance> walletBalances;
  late _MockEVM evm;
  late _MockEverstakeService service;
  late _MockPendingTransaction signed;
  late _MockTransactionHistory history;

  setUpAll(() {
    expect(EverstakeService.source, "0", reason: "_stake encodes source 0, re-capture it");
    S.current = const S();
    registerFallbackValue(_eth("0"));
    registerFallbackValue(_MockWallet());
    registerFallbackValue(WalletType.ethereum);
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(_MockTransactionInfo());
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    wallet = _MockWallet();
    walletBalances = ObservableMap.of({CryptoCurrency.eth: _Balance(_eth("1"))});
    evm = _MockEVM();
    service = _MockEverstakeService();
    history = _MockTransactionHistory();
    final addresses = _MockWalletAddresses();

    when(() => wallet.walletAddresses).thenReturn(addresses);
    when(() => wallet.name).thenReturn("Ethereum staking test");
    when(() => addresses.address).thenReturn(_staker);
    when(() => wallet.balance).thenReturn(walletBalances);
    when(() => wallet.chainId).thenReturn(1);
    when(() => wallet.type).thenReturn(WalletType.ethereum);
    when(() => wallet.transactionHistory).thenReturn(history);
    when(() => wallet.updateTransactionsHistory()).thenAnswer((_) async {});
    when(() => wallet.updateBalance()).thenAnswer((_) async {});
    when(
      () => evm.getTransactionInfo(
        id: "0x1234",
        height: 0,
        amount: any(named: "amount"),
        fee: _eth("0.002"),
        tokenSymbol: "ETH",
        direction: TransactionDirection.outgoing,
        isPending: true,
        date: any(named: "date"),
        confirmations: 0,
        chainId: 1,
      ),
    ).thenReturn(_MockTransactionInfo());

    when(() => service.getEthereumMinStakeAmount()).thenAnswer((_) async => _eth("0.01"));
    when(() => service.getEthereumFee()).thenAnswer((_) async => 0.1);
    when(() => service.getEthereumUserBalances(any())).thenAnswer((_) async => _balances());
    when(() => service.getEthereumRestakedRewards(any())).thenAnswer((_) async => _eth("0"));
    when(() => service.getEthereumWithdrawRequest(any())).thenAnswer(
      (_) async =>
          EverstakeEthereumWithdrawRequest.fromJson({"requested": "0", "readyForClaim": "0"}),
    );
    when(() => service.getEthereumApr()).thenAnswer((_) async => 0.026);
    when(() => service.getEthereumActivationTime())
        .thenAnswer((_) async => const Duration(hours: 547, minutes: 16));
    when(() => service.getEthereumTotalRewards(any())).thenAnswer((_) async => _eth("0"));
    when(
      () => service.prepareEthereumStake(
        address: any(named: "address"),
        amount: any(named: "amount"),
      ),
    ).thenAnswer(
      (invocation) async => EverstakeEthereumTransaction.fromJson(
        _stake,
        value: invocation.namedArguments[#amount] as Money,
      ),
    );

    signed = _MockPendingTransaction();
    when(() => signed.fee).thenReturn(_eth("0.002"));
    when(() => signed.amount).thenReturn(_eth("0.1"));
    when(() => signed.evmTxHashFromRawHex).thenReturn("0x1234");
    when(() => signed.commit()).thenAnswer((_) async {});
    when(
      () => evm.createRawCallDataTransaction(
        any(),
        any(),
        any(),
        any(),
        any(),
        useBlinkProtection: any(named: "useBlinkProtection"),
      ),
    ).thenAnswer((_) async => signed);
  });

  Future<EverstakeBloc> loadedBloc() async {
    final settingsStore = _MockSettingsStore();
    when(() => settingsStore.getPriority(any(), chainId: any(named: "chainId"))).thenReturn(null);
    when(() => settingsStore.useBlinkProtection).thenReturn(true);
    when(() => settingsStore.languageCode).thenReturn("en");

    final bloc = EverstakeBloc(
      wallet: wallet,
      settingsStore: settingsStore,
      evm: evm,
      service: service,
      validator: EverstakeEthereumTransactionValidator(),
    );
    addTearDown(bloc.close);
    await bloc.stream.firstWhere((state) => state is EverstakeReady);
    return bloc;
  }

  Future<EverstakeState> prepared(EverstakeBloc bloc, TransactionRequested event) {
    final result = bloc.stream.firstWhere(
      (state) => state is EverstakePrepared || state is EverstakeFailure,
    );
    bloc.add(event);
    return result;
  }

  group("loads Everstake's display figures", () {
    test("with lifetime rewards as earned", () async {
      when(() => service.getEthereumRestakedRewards(any())).thenAnswer((_) async => _eth("0.01"));
      when(() => service.getEthereumTotalRewards(any())).thenAnswer((_) async => _eth("0.03"));
      final bloc = await loadedBloc();

      final data = bloc.state.data!;
      expect(data.apr, 0.026);
      expect(data.activationTime, const Duration(hours: 547, minutes: 16));
      expect(data.earned, _eth("0.03"));
    });

    test("and goes without them when those requests fail", () async {
      when(() => service.getEthereumRestakedRewards(any())).thenAnswer((_) async => _eth("0.01"));
      when(() => service.getEthereumApr())
          .thenAnswer((_) => Future.error(const EverstakeResponseException("", 500)));
      when(() => service.getEthereumActivationTime())
          .thenAnswer((_) => Future.error(const EverstakeResponseException("", 500)));
      when(() => service.getEthereumTotalRewards(any()))
          .thenAnswer((_) => Future.error(const EverstakeResponseException("\"address\"", 400)));
      final bloc = await loadedBloc();

      final data = bloc.state.data!;
      expect(data.apr, isNull);
      expect(data.activationTime, isNull);
      expect(data.earned, _eth("0.01"));
    });
  });

  group("max deposit", () {
    test("holds back twice the fee of staking the whole balance", () async {
      when(() => evm.estimateRawCallDataTransactionFee(any(), any(), any(), _eth("1"), any()))
          .thenAnswer((_) async => _eth("0.003"));
      final bloc = await loadedBloc();

      final state = await prepared(bloc, const MaxStakeRequested());

      expect(
        state,
        isA<EverstakePrepared>()
            .having((s) => s.operation.action, "action", EverstakeAction.stake)
            .having((s) => s.operation.amount, "amount", _eth("0.994")),
      );
    });

    test("refuses a balance below the minimum stake", () async {
      walletBalances[CryptoCurrency.eth] = _Balance(_eth("0.005"));
      final bloc = await loadedBloc();

      final state = await prepared(bloc, const MaxStakeRequested());

      expect(
        state,
        isA<EverstakeFailure>()
            .having((s) => s.error, "error", S.current.error_text_input_below_minimum_limit),
      );
      verifyNever(
        () => service.prepareEthereumStake(
          address: any(named: "address"),
          amount: any(named: "amount"),
        ),
      );
    });
  });

  test("refuses a transaction whose gas couldn't be estimated", () async {
    when(() => signed.fee).thenReturn(_eth("0"));
    final bloc = await loadedBloc();

    final state = await prepared(bloc, StakeRequested(_eth("0.1")));

    expect(
      state,
      isA<EverstakeFailure>().having((s) => s.error, "error", S.current.tx_zero_fee_exception),
    );
  });

  test("never signs a stake Everstake built for another contract", () async {
    when(
      () => service.prepareEthereumStake(
        address: any(named: "address"),
        amount: any(named: "amount"),
      ),
    ).thenAnswer(
      (invocation) async => EverstakeEthereumTransaction.fromJson(
        {..._stake, "to": "0x000000000000000000000000000000000000dEaD"},
        value: invocation.namedArguments[#amount] as Money,
      ),
    );
    final bloc = await loadedBloc();

    final state = await prepared(bloc, StakeRequested(_eth("0.1")));

    expect(
      state,
      isA<EverstakeFailure>()
          .having((s) => s.error, "error", S.current.provider_error("Everstake")),
    );
    verifyNever(
      () => evm.createRawCallDataTransaction(
        any(),
        any(),
        any(),
        any(),
        any(),
        useBlinkProtection: any(named: "useBlinkProtection"),
      ),
    );
  });

  test("checks a stake against the balance now, not when the data loaded", () async {
    final bloc = await loadedBloc();
    await prepared(bloc, StakeRequested(_eth("0.1")));

    // Spent elsewhere while the first stake was under review, so no reload ran.
    runInAction(() => walletBalances[CryptoCurrency.eth] = _Balance(_eth("0.5")));
    final state = await prepared(bloc, StakeRequested(_eth("0.8")));

    expect(
      state,
      isA<EverstakeFailure>()
          .having((s) => s.error, "error", S.current.error_text_input_above_maximum_limit),
    );
  });

  test("reports the minimum remaining pending stake", () async {
    when(() => service.getEthereumUserBalances(any()))
        .thenAnswer((_) async => _balances(pending: "0.02"));
    final bloc = await loadedBloc();

    final state = await prepared(bloc, PendingUnstakeRequested(_eth("0.015")));

    expect(
      state,
      isA<EverstakeFailure>().having(
        (s) => s.error,
        "error",
        S.current.staking_remainder_below_minimum(
          _eth("0.01").toLocalStringWithSymbol(locale: "en"),
        ),
      ),
    );
  });

  group("when a transaction moves the wallet balance", () {
    test("reloads", () async {
      final bloc = await loadedBloc();
      final reloaded = bloc.stream.firstWhere((state) => state is EverstakeReady);

      runInAction(() => walletBalances[CryptoCurrency.eth] = _Balance(_eth("0.5")));

      expect((await reloaded).data!.walletBalance, _eth("0.5"));
      verify(() => service.getEthereumUserBalances(_staker)).called(2);
    });

    test("keeps the transaction under review", () async {
      final bloc = await loadedBloc();
      final review = await prepared(bloc, StakeRequested(_eth("0.1")));

      runInAction(() => walletBalances[CryptoCurrency.eth] = _Balance(_eth("0.5")));
      await pumpEventQueue();

      expect(bloc.state, same(review));
      verify(() => service.getEthereumUserBalances(_staker)).called(1);
    });
  });

  test("submits only the reviewed transaction and records it as pending", () async {
    final bloc = await loadedBloc();
    final first = await prepared(bloc, StakeRequested(_eth("0.05"))) as EverstakePrepared;
    final second = await prepared(bloc, StakeRequested(_eth("0.1"))) as EverstakePrepared;

    bloc.add(TransactionConfirmed(first.operation));
    await pumpEventQueue();

    expect(bloc.state, same(second));
    verifyNever(() => signed.commit());

    final submitted = bloc.stream.firstWhere((state) => state is EverstakeSubmitted);
    bloc.add(TransactionConfirmed(second.operation));

    expect(
      await submitted,
      isA<EverstakeSubmitted>().having((s) => s.operation, "operation", same(second.operation)),
    );
    verify(() => signed.commit()).called(1);
    verify(() => history.addOne(any())).called(1);
  });

  test("prepares an active unstake with its instant payout estimate", () async {
    final amount = _eth("0.5");
    final instantAmount = _eth("0.2");
    final transaction = EverstakeEthereumTransaction.fromJson(
      {
        "from": _staker,
        "to": "0xD523794C879D9eC028960a231F866758e405bE34",
        "data":
            "0x76ec871c00000000000000000000000000000000000000000000000006f05b59d3b2000000000000000000000000000000000000000000000000000000000000000000050000000000000000000000000000000000000000000000000000000000000000",
      },
      value: _eth("0"),
    );
    when(() => service.getEthereumUserBalances(any()))
        .thenAnswer((_) async => _balances(autocompound: "1"));
    when(
      () => service.simulateEthereumUnstake(
        address: _staker,
        amount: amount,
        allowedInterchangeNum: 5,
      ),
    ).thenAnswer((_) async => instantAmount);
    when(
      () => service.prepareEthereumUnstake(
        address: _staker,
        amount: amount,
        allowedInterchangeNum: 5,
      ),
    ).thenAnswer((_) async => transaction);
    final bloc = await loadedBloc();

    final state = await prepared(bloc, UnstakeRequested(amount));

    expect(
      state,
      isA<EverstakePrepared>()
          .having((s) => s.operation.action, "action", EverstakeAction.unstake)
          .having((s) => s.operation.amount, "amount", amount)
          .having((s) => s.operation.instantUnstakeAmount, "instantUnstakeAmount", instantAmount),
    );
    verify(
      () => evm.createRawCallDataTransaction(
        wallet,
        transaction.to,
        transaction.data,
        _eth("0"),
        null,
        useBlinkProtection: true,
      ),
    ).called(1);
  });

  test("prepares the claim of a withdrawal that is ready", () async {
    when(() => service.getEthereumWithdrawRequest(any())).thenAnswer(
      (_) async => EverstakeEthereumWithdrawRequest.fromJson({
        "requested": "0.5",
        "readyForClaim": "0.5",
      }),
    );
    when(() => service.prepareEthereumClaimWithdrawRequest(_staker)).thenAnswer(
      (_) async => EverstakeEthereumTransaction.fromJson(
        {
          "from": _staker,
          "to": "0x7a7f0b3c23C23a31cFcb0c44709be70d4D545c6e",
          "data": "0x33986ffa",
        },
        value: _eth("0"),
      ),
    );
    final bloc = await loadedBloc();

    final state = await prepared(bloc, const WithdrawalClaimRequested());

    expect(
      state,
      isA<EverstakePrepared>()
          .having((s) => s.operation.action, "action", EverstakeAction.claimWithdrawal)
          .having((s) => s.operation.amount, "amount", _eth("0.5")),
    );
  });

  test("selects pending stake for withdrawal before active stake", () {
    EverstakeData data(EverstakeEthereumUserBalances balances) => EverstakeData(
          minStakeAmount: _eth("0.01"),
          poolFee: 0.1,
          balances: balances,
          restakedRewards: _eth("0"),
          withdrawRequest:
              EverstakeEthereumWithdrawRequest.fromJson({"requested": "0", "readyForClaim": "0"}),
          walletBalance: _eth("1"),
        );

    final waiting = data(_balances(pending: "0.05", pendingDeposited: "0.2", autocompound: "1"));
    expect(waiting.stakedBalance, _eth("1.25"));
    expect(waiting.withdrawsPendingStake, isTrue);
    expect(waiting.withdrawableBalance, _eth("0.05"));

    final activating = data(_balances(pendingDeposited: "0.2", autocompound: "1"));
    expect(activating.withdrawsPendingStake, isFalse);
    expect(activating.withdrawableBalance, _eth("1"));
  });
}
