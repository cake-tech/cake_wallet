import "dart:async";

import "package:bloc/bloc.dart";
import "package:bloc_concurrency/bloc_concurrency.dart";
import "package:bloc_presentation/bloc_presentation.dart";
import "package:cake_wallet/core/address_resolver/address_resolver_service.dart";
import "package:cake_wallet/core/address_validator.dart";
import "package:cake_wallet/core/trade_monitor.dart";
import "package:cake_wallet/core/utilities.dart";
import "package:cake_wallet/di.dart";
import "package:cake_wallet/entities/fiat_currency.dart";
import "package:cake_wallet/exchange/exchange_provider_description.dart";
import "package:cake_wallet/exchange/provider/exchange_provider.dart";
import "package:cake_wallet/exchange/rate_request.dart";
import "package:cake_wallet/exchange/trade.dart";
import "package:cake_wallet/exchange/trade_request.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/services/transaction_service.dart";
import "package:cake_wallet/new-ui/services/wallet_switch_service.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/bloc/swap_presentation_event.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/currency_provider.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/provider_registry.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/rates/rate_cubit.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/swap_address_resolver.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/trade_creator.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/fees_helper.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/swap_address.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/swap_amount.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/swap_source.dart";
import "package:cake_wallet/reactions/wallet_utils.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cake_wallet/store/dashboard/fiat_conversion_store.dart";
import "package:cake_wallet/utils/exchange_provider_logger.dart";
import "package:cake_wallet/utils/list_extension.dart";
import "package:cake_wallet/view_model/send/output.dart";
import "package:cw_core/amount/exchange_rate.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/pending_transaction.dart";
import "package:cw_core/sync_status.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:meta/meta.dart";

part "swap_event.dart";

part "swap_state.dart";

class SwapBloc extends Bloc<SwapEvent, SwapState>
    with BlocPresentationMixin<SwapState, SwapPresentationEvent> {
  SwapBloc({
    required FeesHelper feesHelper, required TradeCreator creator, required SwapAddressResolver addressResolver,
    required AddressResolverService addressResolverService,
    required TransactionService transactionService,
    required TradeMonitor tradeMonitor,
    required WalletSwitchService walletSwitchService,
    required this.rateCubit,
    required this.currencyStore,
    required SwapAmountFactory amountFactory,
    required ExchangeProviderRegistry registry,
    required AppStore appStore,
  })
      : _feesHelper = feesHelper,
        _creator = creator,
        _addressResolver = addressResolver,
       _addressResolverService = addressResolverService,
       _transactionService = transactionService,
       _tradeMonitor = tradeMonitor,
       _walletSwitchService = walletSwitchService,
       _amountFactory = amountFactory,
       _registry = registry,
       _appStore = appStore,
       super(const SwapStateNotLoaded()) {
    on<_Init>(_init);
    on<InitialValuesApplied>(_onInitialValuesApplied, transformer: sequential());
    on<SourceChanged>(_onSourceChanged, transformer: sequential());
    on<PayoutAddressChanged>(_onPayoutAddressChanged, transformer: restartable());
    on<DepositAmountChanged>(_onDepositAmountChanged, transformer: restartable());
    on<PayoutAmountChanged>(_onPayoutAmountChanged, transformer: restartable());
    on<SwapAllEnabled>(_onSwapAllEnabled, transformer: droppable());
    on<RatesLoadStarted>(_onRatesLoadStarted, transformer: droppable());
    on<DepositCurrencyChanged>(_onDepositCurrencyChanged, transformer: restartable());
    on<PayoutCurrencyChanged>(_onPayoutCurrencyChanged, transformer: restartable());
    on<SwapDirectionReversed>(_onSwapDirectionReversed, transformer: sequential());
    on<ForcedProviderSelected>(_onForcedProviderSelected, transformer: restartable());
    on<ProviderToggled>(_onProviderToggled, transformer: sequential());
    on<FixedRateToggled>(_onFixedRateToggled, transformer: sequential());
    on<FiatCurrencyChanged>(_onFiatCurrencyChanged);
    on<ForceDecentralizedExchangesToggled>(
      _onForceDecentralizedExchangesToggled,
      transformer: sequential(),
    );
    on<SwapInitiated>(_onSwapInitiated, transformer: droppable());
    on<SendConfirmed>(_onSendConfirmed, transformer: droppable());
    on<MemoChanged>(_onMemoChanged, transformer: restartable());
    on<DefaultFeeSelected>(_onDefaultFeeSelected, transformer: sequential());
    add(_Init());
  }

  final AppStore _appStore;
  WalletBase get wallet => _appStore.wallet!;
  final AddressResolverService _addressResolverService;
  final TransactionService _transactionService;
  final TradeMonitor _tradeMonitor;
  final WalletSwitchService _walletSwitchService;
  final ExchangeProviderRegistry _registry;
  final RateCubit rateCubit;
  final SwapAmountFactory _amountFactory;
  final SwapCurrencyStore currencyStore;
  final SwapAddressResolver _addressResolver;
  final TradeCreator _creator;
  final FeesHelper _feesHelper;
  Timer? _rateTimer;

  FiatCurrency get fiat => _appStore.settingsStore.fiatCurrency;

  Money get spendingBalance {
    if (state case final SwapStateWithInputs s) {
      return _appStore
              .wallet!
              .balance[_appStore.wallet!.balance.keys.firstWhereOrNull(
                (item) => item.symbol == s.depositAmount.currency.symbol,
              )]
              ?.available ??
          Money.zero(s.depositAmount.currency);
    }
    return _appStore.wallet!.balance[_appStore.wallet!.currency]?.available ??
        Money.zero(_appStore.wallet!.currency);
  }

  Future<void> _reloadRates() async {
    if (state case final SwapStateWithInputs s when s is! SwapStateWithTrade) {
      await rateCubit.fetchRates(s.usableProviders, s.rateRequest, isExternalSend: s.isExternalSend);
    }
  }

  ExchangeRate? _bestRate(SwapInputState s) => switch (rateCubit.state) {
    final RatesLoaded rs
        when {rs.request.depositCurrency, rs.request.payoutCurrency}
            .containsAll({s.depositAmount.currency, s.payoutAmount.currency}) =>
      rs.rates.max.rate,
    _ => null,
  };

  bool _ratesAreCurrent() {
    if (state case final SwapInputState s) {
      return rateCubit.state.request == s.rateRequest;
    }
    return true;
  }

  bool _samePair(SwapInputState now, SwapInputState before) =>
      now.depositAmount.currency == before.depositAmount.currency &&
      now.payoutAmount.currency == before.payoutAmount.currency;

  bool _sameInputs(SwapInputState now, SwapInputState before) =>
      _samePair(now, before) &&
      now.isFixedRate == before.isFixedRate &&
      (now.isFixedRate
          ? now.payoutAmount.cryptoAmount == before.payoutAmount.cryptoAmount
          : now.depositAmount.cryptoAmount == before.depositAmount.cryptoAmount);

  Future<void> _init(_Init event, Emitter<SwapState> emit) async {
    final initialDepositCurrency = _appStore.wallet!.currency;
    final initialPayoutCurrency = initialDepositCurrency == CryptoCurrency.xmr
        ? CryptoCurrency.btc
        : CryptoCurrency.xmr;

    final initialDepositAmount = SwapAmount(
      cryptoAmount: Money.zero(initialDepositCurrency),
      fiatAmount: Money.zero(_appStore.settingsStore.fiatCurrency),
    );
    final initialPayoutAmount = SwapAmount(
      cryptoAmount: Money.zero(initialPayoutCurrency),
      fiatAmount: Money.zero(_appStore.settingsStore.fiatCurrency),
    );

    _rateTimer = Timer.periodic(const Duration(seconds: 10), (_) => add(RatesLoadStarted()));

    emit(
      SwapInputState(
        depositAmount: initialDepositAmount,
        payoutAmount: initialPayoutAmount,
        hasSwapAll: _amountFactory.hasSwapAll,
        source: InternalSwapSource(_appStore.wallet!.walletInfo),
        payoutAddress: null,
        memo: "",
        isFixedRate: false,
        availableProviders: _registry.allProviders,
        enabledProviders: _registry.enabledProviders,
        forceDecentralizedProviders: _appStore.settingsStore.forceDecentralizedExchanges,
      ),
    );

    if(_feesHelper.isLowFee) {
      emitPresentation(const LowFeeAlert());
    }
  }

  @override
  Future<void> close() async {
    _rateTimer?.cancel();
    await super.close();
  }

  Future<void> _onSourceChanged(SourceChanged event, Emitter<SwapState> emit) async {
    if (state case final SwapInputState s
        when !_isValidRefundAddress(event.newSource, s.depositAmount.currency)) {
      emitPresentation(AddressValidationFailed(s.depositAmount.currency));
      return;
    }

    var isWalletSwitched = false;
    if (event.newSource case final InternalSwapSource source
        when source.sourceWallet.internalId != _appStore.wallet!.walletInfo.internalId) {
      try {
        await _walletSwitchService.switchToWallet(source.sourceWallet);
        isWalletSwitched = true;
      } catch (e) {
        emitPresentation(WalletSwitchFailed(e));
        return;
      }
    }

    if (state case final SwapInputState s) {
      if (s.isSwapAll && (isWalletSwitched || event.newSource is ExternalSwapSource)) {
        final depositAmount = await _amountFactory.getSwapAmount(
          Money.zero(s.depositAmount.currency),
          s.depositAmount.currency,
        );
        final payoutAmount = await _amountFactory.getSwapAmount(
          Money.zero(s.payoutAmount.currency),
          s.payoutAmount.currency,
        );
        if (state case final SwapInputState current when _samePair(current, s)) {
          emit(
            current.copyWith(
              source: event.newSource,
              hasSwapAll: _amountFactory.hasSwapAll,
              depositAmount: depositAmount,
              payoutAmount: payoutAmount,
            ),
          );
        }
      } else {
        emit(s.copyWith(source: event.newSource, hasSwapAll: _amountFactory.hasSwapAll));
      }
      add(RatesLoadStarted());
      if (event.initiateSwap) {
        add(SwapInitiated());
      }
    }
  }

  bool _isValidRefundAddress(SwapSource source, CryptoCurrency currency) =>
      switch (source.refundAddress) {
        null || "" => true,
        final address => AddressValidator(type: currency).isValid(address),
      };

  Future<void> _onInitialValuesApplied(InitialValuesApplied event, Emitter<SwapState> emit) async {
    if (state case final SwapInputState s) {
      final depositCurrency = event.depositCurrency ?? s.depositAmount.currency;
      final payoutCurrency = event.payoutCurrency ?? s.payoutAmount.currency;
      final isSamePayoutChain = _isSameChain(s.payoutAmount.currency, payoutCurrency);

      final payoutAddress = event.payoutAddress != null
          ? await _resolvePayoutAddress(event.payoutAddress!, payoutCurrency)
          : (isSamePayoutChain ? s.payoutAddress : null);

      final depositAmount = await _amountFactory.getSwapAmount(
        (event.payoutAmount == null ? event.depositAmount : null) ?? Money.zero(depositCurrency),
        depositCurrency,
      );
      final payoutAmount = await _amountFactory.getSwapAmount(
        event.payoutAmount ?? Money.zero(payoutCurrency),
        payoutCurrency,
      );

      if (state case final SwapInputState current when _samePair(current, s)) {
        emit(
          current.copyWith(
            isFixedRate: event.payoutAmount != null,
            depositAmount: depositAmount,
            payoutAmount: payoutAmount,
            source: _isSameChain(s.depositAmount.currency, depositCurrency)
                ? current.source
                : const ExternalSwapSource(""),
            memo: isSamePayoutChain && payoutCurrency.memoLabelType != null ? current.memo : "",
            payoutAddress: () => payoutAddress,
          ),
        );
        add(RatesLoadStarted());
      }
    }
  }

  Future<void> _onPayoutAddressChanged(PayoutAddressChanged event, Emitter<SwapState> emit) async {
    if (state case final SwapInputState s) {
      final newAddress = await _resolvePayoutAddress(event.newAddress, s.payoutAmount.currency);
      if (state case final SwapInputState current
          when newAddress != null && current.payoutAmount.currency == s.payoutAmount.currency) {
        emit(current.copyWith(payoutAddress: () => newAddress));
      }
    }
  }

  Future<SwapAddress?> _resolvePayoutAddress(SwapAddress address, CryptoCurrency currency) async {
    SwapAddress newAddress = address;
    if (address is ExternalSwapAddress) {
      final parsed = await _addressResolverService.resolve(
        query: address.address,
        wallet: _appStore.wallet!,
        currency: currency,
      );
      if (parsed.isNotEmpty) {
        final parsedAddr = parsed.first;
        emitPresentation(AliaspayAddressFound(parsedAddr));
        newAddress = PayAnythingSwapAddress(parsedAddr, currency);
      }
    }

    if (newAddress is! InternalWalletSwapAddress &&
        !AddressValidator(type: currency).isValid(newAddress.address)) {
      emitPresentation(AddressValidationFailed(currency));
      return null;
    }

    return newAddress;
  }

  Future<void> _onDepositAmountChanged(DepositAmountChanged event, Emitter<SwapState> emit) async {
    if (state case final SwapInputState s) {
      final newDepositAmount = await _amountFactory.getSwapAmount(
        event.newAmount,
        s.depositAmount.currency,
      );

      final newPayoutCryptoAmount =
          _bestRate(s)?.convert(newDepositAmount.cryptoAmount) ??
          Money.zero(s.payoutAmount.currency);

      final newPayoutAmount = await _amountFactory.getSwapAmount(
        newPayoutCryptoAmount,
        s.payoutAmount.currency,
      );

      if (state case final SwapInputState current when _samePair(current, s)) {
        emit(
          current.copyWith(
            isFixedRate: false,
            depositAmount: newDepositAmount,
            payoutAmount: newPayoutAmount,
          ),
        );
        add(RatesLoadStarted());
      }
    }
  }

  Future<void> _onPayoutAmountChanged(PayoutAmountChanged event, Emitter<SwapState> emit) async {
    if (state case final SwapInputState s) {
      final newPayoutAmount = await _amountFactory.getSwapAmount(
        event.newAmount,
        s.payoutAmount.currency,
      );

      final newDepositCryptoAmount =
          _bestRate(s)?.convert(newPayoutAmount.cryptoAmount) ??
          Money.zero(s.depositAmount.currency);

      final newDepositAmount = await _amountFactory.getSwapAmount(
        newDepositCryptoAmount,
        s.depositAmount.currency,
      );

      if (state case final SwapInputState current when _samePair(current, s)) {
        emit(
          current.copyWith(
            isFixedRate: true,
            depositAmount: newDepositAmount,
            payoutAmount: newPayoutAmount,
          ),
        );
        add(RatesLoadStarted());
      }
    }
  }

  Future<void> _onSwapAllEnabled(SwapAllEnabled event, Emitter<SwapState> emit) async {
    if (state case final SwapInputState s) {
      if (_appStore.wallet!.syncStatus is! SyncedSyncStatus) {
        // enabling swap all on an unsynced wallet would lead to garbage results because balances either won't match or won't exist.
        emitPresentation(const SwapAllNotReady());
        return;
      }

      final newDepositAmount = await _amountFactory.getSwapAllAmount(s.depositAmount.currency);
      final newPayoutCryptoAmount =
          _bestRate(s)?.convert(newDepositAmount.cryptoAmount) ??
          Money.zero(s.payoutAmount.currency);

      final newPayoutAmount = await _amountFactory.getSwapAmount(
        newPayoutCryptoAmount,
        s.payoutAmount.currency,
      );

      if (state case final SwapInputState current when _samePair(current, s)) {
        emit(current.copyWith(
            depositAmount: newDepositAmount,
            payoutAmount: newPayoutAmount,
            isFixedRate: false,
        ));
        add(RatesLoadStarted());
      }
    }
  }

  Future<void> _onRatesLoadStarted(RatesLoadStarted event, Emitter<SwapState> emit) async {
    do {
      await _reloadRates();
    } while (!_ratesAreCurrent());

    if (state case final SwapInputState s) {
      if (_bestRate(s) case final rate?) {
        final SwapAmount newDepositAmount;
        final SwapAmount newPayoutAmount;
        if (s.isFixedRate) {
          newDepositAmount = await _amountFactory.getSwapAmount(
            rate.convert(s.payoutAmount.cryptoAmount),
            s.depositAmount.currency,
          );
          newPayoutAmount = s.payoutAmount;
        } else {
          newDepositAmount = s.depositAmount;
          newPayoutAmount = await _amountFactory.getSwapAmount(
            rate.convert(s.depositAmount.cryptoAmount),
            s.payoutAmount.currency,
          );
        }
        if (state case final SwapInputState current when _sameInputs(current, s)) {
          emit(current.copyWith(depositAmount: newDepositAmount, payoutAmount: newPayoutAmount));
        }
      }
    }
  }

  Future<void> _onDepositCurrencyChanged(
    DepositCurrencyChanged event,
    Emitter<SwapState> emit,
  ) async {
    if (state case final SwapInputState s) {
      final SwapAmount newDepositAmount;
      final SwapAmount newPayoutAmount;
      if (s.isSwapAll) {
        final canSendNewCurrency =
            _isSameChain(event.newCurrency, _appStore.wallet!.currency) &&
                _appStore.wallet!.balance.keys.any((item) => item.symbol == event.newCurrency.symbol);

        newDepositAmount = canSendNewCurrency
            ? await _amountFactory.getSwapAllAmount(event.newCurrency)
            : await _amountFactory.getSwapAmount(Money.zero(event.newCurrency), event.newCurrency);
        newPayoutAmount = await _amountFactory.getSwapAmount(
          Money.zero(s.payoutAmount.currency),
          s.payoutAmount.currency,
        );
      } else if (s.isFixedRate) {
        newDepositAmount = await _amountFactory.getSwapAmount(
          Money.zero(event.newCurrency),
          event.newCurrency,
        );
        newPayoutAmount = s.payoutAmount;
      } else {
        newDepositAmount = await _amountFactory.getSwapAmount(
          Money.safeParse(s.depositAmount.cryptoAmount.toString(), event.newCurrency),
          event.newCurrency,
        );
        newPayoutAmount = await _amountFactory.getSwapAmount(
          Money.zero(s.payoutAmount.currency),
          s.payoutAmount.currency,
        );
      }

      if (state case final SwapInputState current when _samePair(current, s)) {
        emit(
          current.copyWith(
            depositAmount: newDepositAmount,
            payoutAmount: newPayoutAmount,
            // the swap all amount is pinned to the deposit side, so it has to be the one driving
            // the rate - otherwise the next rate load would overwrite it.
            isFixedRate: s.isSwapAll ? false : s.isFixedRate,
            source: _isSameChain(s.depositAmount.currency, event.newCurrency)
                ? current.source
                : const ExternalSwapSource(""),
          ),
        );
        add(RatesLoadStarted());
      }
    }
  }

  Future<void> _onPayoutCurrencyChanged(
    PayoutCurrencyChanged event,
    Emitter<SwapState> emit,
  ) async {
    if (state case final SwapInputState s) {
      final SwapAmount newDepositAmount;
      final SwapAmount newPayoutAmount;
      if (s.isFixedRate) {
        newDepositAmount = await _amountFactory.getSwapAmount(
          Money.zero(s.depositAmount.currency),
          s.depositAmount.currency,
        );
        newPayoutAmount = await _amountFactory.getSwapAmount(
          Money.safeParse(s.payoutAmount.cryptoAmount.toString(), event.newCurrency),
          event.newCurrency,
        );
      } else {
        newDepositAmount = s.depositAmount;
        newPayoutAmount = await _amountFactory.getSwapAmount(
          Money.zero(event.newCurrency),
          event.newCurrency,
        );
      }

      final isSameChain = _isSameChain(s.payoutAmount.currency, event.newCurrency);

      if (state case final SwapInputState current when _samePair(current, s)) {
        emit(
          current.copyWith(
            depositAmount: newDepositAmount,
            payoutAmount: newPayoutAmount,
            memo: isSameChain && event.newCurrency.memoLabelType != null ? current.memo : "",
            payoutAddress: () => isSameChain ? current.payoutAddress : null,
          ),
        );
        add(RatesLoadStarted());
      }
    }
  }

  Future<void> _onSwapDirectionReversed(
    SwapDirectionReversed event,
    Emitter<SwapState> emit,
  ) async {
    if (state case final SwapInputState s) {
      final SwapAmount newDepositAmount;
      final SwapAmount newPayoutAmount;
      if (s.isFixedRate) {
        newPayoutAmount = s.depositAmount;
        newDepositAmount = await _amountFactory.getSwapAmount(
          Money.zero(s.payoutAmount.currency),
          s.payoutAmount.currency,
        );
      } else {
        newDepositAmount = s.payoutAmount;
        newPayoutAmount = await _amountFactory.getSwapAmount(
          Money.zero(s.depositAmount.currency),
          s.depositAmount.currency,
        );
      }

      final isSameChain = _isSameChain(s.depositAmount.currency, s.payoutAmount.currency);

      if (state case final SwapInputState current when _samePair(current, s)) {
        emit(
          current.copyWith(
            depositAmount: newDepositAmount,
            payoutAmount: newPayoutAmount,
            source: isSameChain ? current.source : const ExternalSwapSource(""),
            payoutAddress: () => isSameChain ? current.payoutAddress : null,
            memo:
                isSameChain && newPayoutAmount.currency.memoLabelType != null ? current.memo : "",
          ),
        );
        add(RatesLoadStarted());
      }
    }
  }

  bool _isSameChain(CryptoCurrency a, CryptoCurrency b) =>
      cryptoCurrencyOrTokenToWalletType(a) != null &&
      cryptoCurrencyOrTokenToWalletType(a) == cryptoCurrencyOrTokenToWalletType(b);

  Future<void> _onForcedProviderSelected(
    ForcedProviderSelected event,
    Emitter<SwapState> emit,
  ) async {
    if (state case final SwapInputState s) {
      emit(s.copyWith(forcedProvider: () => event.provider));
      add(RatesLoadStarted());
    }
  }

  void _onProviderToggled(ProviderToggled event, Emitter<SwapState> emit) {
    if (state case final SwapInputState s) {
      final newProviders = List<ExchangeProviderDescription>.from(s.enabledProviders);
      bool loadRates = false;
      if (newProviders.contains(event.provider)) {
        newProviders.remove(event.provider);
        // if the provider the user disabled was also the one with the best rate, we gotta find a different provider
        if (rateCubit.state case final RatesLoaded rs) {
          if (rs.rates.max.provider == event.provider) {
            loadRates = true;
          }
        }
      } else {
        newProviders.add(event.provider);
        // we have to load rates always since the enabled provider might have a better rate
        loadRates = true;
      }
      emit(s.copyWith(enabledProviders: newProviders));
      if (loadRates) {
        add(RatesLoadStarted());
      }

      _registry.updateProviders(newProviders);
    }
  }

  Future<void> _onFixedRateToggled(FixedRateToggled event, Emitter<SwapState> emit) async {
    if (state case final SwapInputState s) {
      emit(s.copyWith(isFixedRate: !s.isFixedRate));
      add(RatesLoadStarted());
    }
  }

  Future<void> _onFiatCurrencyChanged(FiatCurrencyChanged event, Emitter<SwapState> emit) async {
    _appStore.settingsStore.fiatCurrency = event.newCurrency;
    if (state case final SwapInputState s) {
      final depositAmount = await _amountFactory.getSwapAmount(
        s.depositAmount.cryptoAmount,
        s.depositAmount.currency,
      );
      final payoutAmount = await _amountFactory.getSwapAmount(
        s.payoutAmount.cryptoAmount,
        s.payoutAmount.currency,
      );
      if (state case final SwapInputState current
          when current.depositAmount.cryptoAmount == s.depositAmount.cryptoAmount &&
              current.payoutAmount.cryptoAmount == s.payoutAmount.cryptoAmount) {
        emit(current.copyWith(depositAmount: depositAmount, payoutAmount: payoutAmount));
      }
    }
  }

  Future<void> _onMemoChanged(MemoChanged event, Emitter<SwapState> emit) async {
    if (state case final SwapInputState s) {
      emit(s.copyWith(memo: event.newMemo));
    }
  }

  void _onForceDecentralizedExchangesToggled(
    ForceDecentralizedExchangesToggled event,
    Emitter<SwapState> emit,
  ) {
    if (state case final SwapInputState s) {
      final newState = !s.forceDecentralizedProviders;
      _appStore.settingsStore.forceDecentralizedExchanges = newState;
      emit(
        s.copyWith(
          forceDecentralizedProviders: newState,
          forcedProvider: () =>
              newState && s.forcedProvider?.isCentralized == true ? null : s.forcedProvider,
        ),
      );
      add(RatesLoadStarted());
    }
  }

  Future<void> _onDefaultFeeSelected(DefaultFeeSelected event, Emitter<SwapState> emit) async {
    _feesHelper.setDefaultTransactionPriority();
  }

  Future<void> _onSwapInitiated(SwapInitiated event, Emitter<SwapState> emit) async {
    final inputs = state;
    if (inputs is! SwapInputState) {
      return;
    }

    if (inputs.source case ExternalSwapSource(refundAddress: "")) {
      emitPresentation(RefundAddressRequired(inputs.depositAmount.currency));
      return;
    }

    emitPresentation(const SwapCreationStarted());

    try {
      await _createSwap(emit);
    } catch (e) {
      emit(switch (state) {
        final SwapStateCreating creating => creating.toError(e),
        final SwapInputState s => SwapInitiationError(inputs: s, error: e),
        _ => SwapInitiationError(inputs: inputs, error: e),
      });
    }
  }

  Future<void> _createSwap(Emitter<SwapState> emit) async {
    await _reloadRates();

    if (state case final SwapInputState s) {
      final rates = switch (rateCubit.state) {
        final RatesLoaded rs when _bestRate(s) != null => rs.rates.toList(),
        _ => null,
      };

      if (rates == null) {
        emit(
          SwapInitiationError(
            inputs: s,
            error: Exception(S.current.none_of_selected_providers_can_exchange),
          ),
        );
        return;
      }

      final req = TradeRequest(
        refundAddress: await _addressResolver.resolveRefundAddress(
            s.source, s.depositAmount.currency),
        payoutAddress: await _addressResolver.resolvePayoutAddress(
            s.payoutAddress!, s.payoutAmount.currency),
        depositAmount: s.depositAmount.cryptoAmount,
        payoutAmount: s.payoutAmount.cryptoAmount,
        isFixedRate: s.isFixedRate,
        toAddressExtraId: s.memo,
      );

      final creatingState = SwapStateCreating(
        source: s.source,
        selectedProvider: rates.max.provider,
        request: req,
        depositAmount: s.depositAmount,
        payoutAmount: s.payoutAmount,
        payoutAddress: s.payoutAddress!,
      );

      emit(creatingState);

      final trade = await _creator.createTrade(rates, req);

      if (trade == null) {
        emit(creatingState.toError(Exception(S.current.none_of_selected_providers_can_exchange)));
        return;
      }

      if (_registry.getProvider(trade.provider) is! TransactionRegistrationExchangeProvider) {
        await _creator.persistTrade(trade);
      }

      final depositFiatAmount =
          (await _amountFactory.getSwapAmount(trade.depositAmount, trade.depositCurrency)).fiatAmount;
      final payoutFiatAmount =
          (await _amountFactory.getSwapAmount(trade.payoutAmount, trade.payoutCurrency)).fiatAmount;

      if (s.source case final ExternalSwapSource source) {
        emit(
          SwapAwaitingExternalSend(
            trade: trade,
            source: source,
            depositFiatAmount: depositFiatAmount,
            payoutFiatAmount: payoutFiatAmount,
            payoutAddress: s.payoutAddress!,
            isFixedRate: s.isFixedRate,
          ),
        );
      } else if (s.source case final InternalSwapSource source) {
        final generatingState = SwapGeneratingTransaction(
          trade: trade,
          source: source,
          depositFiatAmount: depositFiatAmount,
          payoutFiatAmount: payoutFiatAmount,
          payoutAddress: s.payoutAddress!,
          isFixedRate: s.isFixedRate,
        );
        emit(generatingState);

        try {
          final tx = await _createSwapTransaction(trade, s.isSwapAll);
          final feeFiatAmount =
              (await _amountFactory.getSwapAmount(tx.fee, tx.fee.currency as CryptoCurrency)).fiatAmount;
          emit(
            SwapAwaitingSend(
              trade: trade,
              transaction: tx,
              feeFiatAmount: feeFiatAmount,
              source: source,
              depositFiatAmount: depositFiatAmount,
              payoutFiatAmount: payoutFiatAmount,
              payoutAddress: s.payoutAddress!,
              isFixedRate: s.isFixedRate,
            ),
          );
        } catch (e) {
          emit(generatingState.toError(e));
        }
      }
    }
  }

  Future<PendingTransaction> _createSwapTransaction(Trade trade, bool isSendAll) async {
    if (_registry.getProvider(trade.provider) case final TransactionCreationExchangeProvider p) {
      if (await p.createTransaction(_appStore.wallet!, trade) case final transaction?) {
        return transaction;
      }
    }

    final curr = trade.depositAmount.currency as CryptoCurrency;
    // FIXME(malik): output should NOT depend on FiatConversionStore. fix after send refactor
    final output = Output(
      _appStore.wallet!,
      _appStore,
      getIt.get<FiatConversionStore>(),
          () => curr,
    );
    if(!isSendAll) {
      output.setCryptoAmount(trade.depositAmount.toString());
    } else {
      output.setSendAll(
          (await _amountFactory.getSwapAllAmount(trade.depositCurrency)).cryptoAmount.toString());
    }
    output.address = trade.fundingAddress;
    return _transactionService.createTransaction([output]);
  }

  Future<void> _onSendConfirmed(SendConfirmed event, Emitter<SwapState> emit) async {
    if (state case final SwapStateWithTransaction s) {
      emit(
        SwapSending(
          trade: s.trade,
          transaction: s.transaction,
          feeFiatAmount: s.feeFiatAmount,
          source: s.source,
          depositFiatAmount: s.depositFiatAmount,
          payoutFiatAmount: s.payoutFiatAmount,
          payoutAddress: s.payoutAddress,
          isFixedRate: s.isFixedRate,
        ),
      );
      try {
        await _transactionService.commitTransaction(s.transaction);
      } catch (e) {
        emit(s.toError(e));
        return;
      }

      final txHash = s.transaction.evmTxHashFromRawHex ?? s.transaction.id;
      final trade = await _registerTransaction(s.trade, txHash);
      unawaited(_tradeMonitor.recordDeposit(trade.id, txHash));

      emit(
        SwapTransactionCommitted(
          trade: trade,
          transaction: s.transaction,
          feeFiatAmount: s.feeFiatAmount,
          source: s.source,
          depositFiatAmount: s.depositFiatAmount,
          payoutFiatAmount: s.payoutFiatAmount,
          payoutAddress: s.payoutAddress,
          isFixedRate: s.isFixedRate,
        ),
      );
      await _hideSwapAddress(trade, s.source);
    }
  }

  Future<Trade> _registerTransaction(Trade trade, String txHash) async {
    if (_registry.getProvider(trade.provider) case final TransactionRegistrationExchangeProvider p) {
      var registered = trade;
      try {
        registered = await p.registerTransaction(trade, txHash);
      } catch (e, st) {
        ExchangeProviderLogger.logError(
          provider: trade.provider,
          error: e,
          stackTrace: st,
          function: "registerTransaction",
          requestData: {"txHash": txHash},
        );
      }

      await _creator.persistTrade(registered);
      return registered;
    }

    return trade;
  }

  Future<void> _hideSwapAddress(Trade trade, SwapSource source) async {
    if (trade.depositCurrency == CryptoCurrency.btcln ||
        (source is InternalSwapSource && source.refundAddress != null) ||
        (!isElectrumWallet(_appStore.wallet!.type) &&
            !<WalletType>[.monero, .zcash].contains(_appStore.wallet!.type))) {
      return;
    }

    try {
      _appStore.wallet!.walletAddresses.hiddenAddresses
          .add(_appStore.wallet!.walletAddresses.addressForExchange);
      await _appStore.wallet!.walletAddresses.saveAddressesInBox();
    } catch (e) {
      printV("failed to hide swap address: $e");
    }
  }
}
