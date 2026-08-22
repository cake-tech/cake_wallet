import "dart:async";

import "package:bloc/bloc.dart";
import "package:bloc_concurrency/bloc_concurrency.dart";
import "package:bloc_presentation/bloc_presentation.dart";
import "package:cake_wallet/core/address_resolver/address_resolver_service.dart";
import "package:cake_wallet/core/address_validator.dart";
import "package:cake_wallet/core/utilities.dart";
import "package:cake_wallet/di.dart";
import "package:cake_wallet/entities/fiat_currency.dart";
import "package:cake_wallet/exchange/exchange_provider_description.dart";
import "package:cake_wallet/exchange/provider/exchange_provider.dart";
import "package:cake_wallet/exchange/trade.dart";
import "package:cake_wallet/exchange/trade_request.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/services/transaction_service.dart";
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
import "package:cake_wallet/store/app_store.dart";
import "package:cake_wallet/store/dashboard/fiat_conversion_store.dart";
import "package:cake_wallet/utils/list_extension.dart";
import "package:cake_wallet/view_model/send/output.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/pending_transaction.dart";
import "package:cw_core/sync_status.dart";
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
       _amountFactory = amountFactory,
       _registry = registry,
       _appStore = appStore,
       super(const SwapStateNotLoaded()) {
    on<_Init>(_init);
    on<SourceChanged>(_onSourceChanged, transformer: restartable());
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
  final AddressResolverService _addressResolverService;
  final TransactionService _transactionService;
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
    if (state case final SwapStateWithInputs s) {
      await rateCubit.fetchRates(
        s.usableProviders,
        from: s.isFixedRate ? s.payoutAmount.cryptoAmount : s.depositAmount.cryptoAmount,
        to: s.isFixedRate ? s.depositAmount.currency : s.payoutAmount.currency,
        isFixedRate: s.isFixedRate,
      );
    }
  }

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

    _rateTimer = Timer.periodic(const Duration(seconds: 4), (_) => add(RatesLoadStarted()));

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
      unawaited(Future.delayed(const Duration(seconds: 1)).then((_) =>
          emitPresentation(const LowFeeAlert())));
    }
  }

  @override
  Future<void> close() async {
    _rateTimer?.cancel();
    await super.close();
  }

  void _onSourceChanged(SourceChanged event, Emitter<SwapState> emit) {
    if (state case final SwapInputState s) {
      emit(s.copyWith(source: event.newSource));
    }
  }

  Future<void> _onPayoutAddressChanged(PayoutAddressChanged event, Emitter<SwapState> emit) async {
    if (state case final SwapInputState s) {
      SwapAddress newAddress = event.newAddress;
      if (event.newAddress is ExternalSwapAddress) {
        final parsed = await _addressResolverService.resolve(
          query: event.newAddress.address,
          wallet: _appStore.wallet!,
          currency: s.payoutAmount.currency,
        );
        if (parsed.isNotEmpty) {
          final parsedAddr = parsed.first;
          emitPresentation(AliaspayAddressFound(parsedAddr));
          newAddress = PayAnythingSwapAddress(parsedAddr, s.payoutAmount.currency);
        }
      }

      if (newAddress is! InternalWalletSwapAddress &&
          !AddressValidator(type: s.payoutAmount.currency).isValid(newAddress.address)) {
        emitPresentation(const AddressValidationFailed());
        return;
      }

      emit(s.copyWith(payoutAddress: () => newAddress));
    }
  }

  Future<void> _onDepositAmountChanged(DepositAmountChanged event, Emitter<SwapState> emit) async {
    if (state case final SwapInputState s) {
      final newDepositAmount = await _amountFactory.getSwapAmount(
        event.newAmount,
        s.depositAmount.currency,
      );

      final Money newPayoutCryptoAmount;
      if (rateCubit.state case final RatesLoaded l) {
        newPayoutCryptoAmount = l.rates.max.rate.convert(newDepositAmount.cryptoAmount);
      } else {
        newPayoutCryptoAmount = Money.zero(s.payoutAmount.currency);
      }

      final newPayoutAmount = await _amountFactory.getSwapAmount(
        newPayoutCryptoAmount,
        s.payoutAmount.currency,
      );

      emit(
        s.copyWith(
          isFixedRate: false,
          depositAmount: newDepositAmount,
          payoutAmount: newPayoutAmount,
        ),
      );
      add(RatesLoadStarted());
    }
  }

  Future<void> _onPayoutAmountChanged(PayoutAmountChanged event, Emitter<SwapState> emit) async {
    if (state case final SwapInputState s) {
      final newPayoutAmount = await _amountFactory.getSwapAmount(
        event.newAmount,
        s.payoutAmount.currency,
      );

      final Money newDepositCryptoAmount;
      if (rateCubit.state case final RatesLoaded l) {
        newDepositCryptoAmount = l.rates.max.rate.convert(newPayoutAmount.cryptoAmount);
      } else {
        newDepositCryptoAmount = Money.zero(s.depositAmount.currency);
      }

      final newDepositAmount = await _amountFactory.getSwapAmount(
        newDepositCryptoAmount,
        s.depositAmount.currency,
      );

      emit(
        s.copyWith(
          isFixedRate: true,
          depositAmount: newDepositAmount,
          payoutAmount: newPayoutAmount,
        ),
      );
      add(RatesLoadStarted());
    }
  }

  Future<void> _onSwapAllEnabled(SwapAllEnabled event, Emitter<SwapState> emit) async {
    if (state case final SwapInputState s) {
      if (_appStore.wallet!.syncStatus is! SyncedSyncStatus) {
        // enabling swap all on an unsynced wallet would lead to garbage results because balances either won't match or won't exist.
        emitPresentation(const SwapAllNotReady());
      }

      final newDepositAmount = await _amountFactory.getSwapAllAmount(s.depositAmount.currency);
      final Money newPayoutCryptoAmount;
      if (rateCubit.state case final RatesLoaded l) {
        newPayoutCryptoAmount = l.rates.max.rate.convert(newDepositAmount.cryptoAmount);
      } else {
        newPayoutCryptoAmount = Money.zero(s.payoutAmount.currency);
      }

      final newPayoutAmount = await _amountFactory.getSwapAmount(
        newPayoutCryptoAmount,
        s.payoutAmount.currency,
      );

      emit(s.copyWith(
          depositAmount: newDepositAmount,
          payoutAmount: newPayoutAmount,
          isFixedRate: false,
      ));
    }
  }

  Future<void> _onRatesLoadStarted(RatesLoadStarted event, Emitter<SwapState> emit) async {
    await _reloadRates();
    if (state case final SwapInputState s) {
      if (rateCubit.state case final RatesLoaded rs) {
        final SwapAmount newDepositAmount;
        final SwapAmount newPayoutAmount;
        if (s.isFixedRate) {
          newDepositAmount = await _amountFactory.getSwapAmount(
            rs.rates.max.rate.convert(s.payoutAmount.cryptoAmount),
            s.depositAmount.currency,
          );
          newPayoutAmount = s.payoutAmount;
        } else {
          newDepositAmount = s.depositAmount;
          newPayoutAmount = await _amountFactory.getSwapAmount(
            rs.rates.max.rate.convert(s.depositAmount.cryptoAmount),
            s.payoutAmount.currency,
          );
        }
        emit(s.copyWith(depositAmount: newDepositAmount, payoutAmount: newPayoutAmount));
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
        final newCurrencyWalletType = cryptoCurrencyOrTokenToWalletType(event.newCurrency);
        final canSendNewCurrency =
            newCurrencyWalletType == _appStore.wallet!.type &&
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

      SwapSource newSource = s.source;
      if (s.source case final InternalSwapSource iss) {
        if (cryptoCurrencyOrTokenToWalletType(event.newCurrency) != iss.sourceWallet.type) {
          newSource = const ExternalSwapSource("");
        }
      }

      emit(
        s.copyWith(
          depositAmount: newDepositAmount,
          payoutAmount: newPayoutAmount,
          // the swap all amount is pinned to the deposit side, so it has to be the one driving
          // the rate - otherwise the next rate load would overwrite it.
          isFixedRate: s.isSwapAll ? false : s.isFixedRate,
          source: newSource,
        ),
      );
      add(RatesLoadStarted());
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
          Money(s.payoutAmount.cryptoAmount.amount, event.newCurrency),
          event.newCurrency,
        );
      } else {
        newDepositAmount = s.depositAmount;
        newPayoutAmount = await _amountFactory.getSwapAmount(
          Money.zero(event.newCurrency),
          event.newCurrency,
        );
      }

      String newMemo = s.memo;
      if (event.newCurrency.memoLabelType == null) {
        newMemo = "";
      }

      SwapAddress? newPayoutddress = s.payoutAddress;
      if (cryptoCurrencyOrTokenToWalletType(s.payoutAmount.currency) !=
          cryptoCurrencyOrTokenToWalletType(event.newCurrency)) {
        newPayoutddress = null;
      }

      emit(
        s.copyWith(
          depositAmount: newDepositAmount,
          payoutAmount: newPayoutAmount,
          memo: newMemo,
          payoutAddress: () => newPayoutddress,
        ),
      );
      add(RatesLoadStarted());
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
      emit(s.copyWith(depositAmount: newDepositAmount, payoutAmount: newPayoutAmount));
      add(RatesLoadStarted());
    }
  }

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
      emit(
        s.copyWith(
          depositAmount: await _amountFactory.getSwapAmount(
            s.depositAmount.cryptoAmount,
            s.depositAmount.currency,
          ),
          payoutAmount: await _amountFactory.getSwapAmount(
            s.payoutAmount.cryptoAmount,
            s.payoutAmount.currency,
          ),
        ),
      );
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
      emit(s.copyWith(forceDecentralizedProviders: newState));
    }
  }

  Future<void> _onDefaultFeeSelected(DefaultFeeSelected event, Emitter<SwapState> emit) async {
    _feesHelper.setDefaultTransactionPriority();
  }

  Future<void> _onSwapInitiated(SwapInitiated event, Emitter<SwapState> emit) async {
    emitPresentation(const SwapCreationStarted());
    await _reloadRates();
    if(rateCubit.state is! RatesLoaded) {
      return;
    }
    final rates = (rateCubit.state as RatesLoaded).rates.toList();

    if (state case final SwapStateWithInputs s) {
      if(s.source case final InternalSwapSource source) {
        if(source.sourceWallet.internalId != _appStore.wallet!.walletInfo.internalId) {
          emit(SwapAwaitingWalletSwitch(depositAmount: s.depositAmount,
              isFixedRate: s.isFixedRate,
              memo: s.memo,
              payoutAmount: s.payoutAmount,
              usableProviders: s.usableProviders,
              source: source));
        }
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
      );

      emit(creatingState);

      final trade = await _creator.createTrade(rates, req);


      if (trade == null) {
        emit(creatingState.toError(Exception(S.current.none_of_selected_providers_can_exchange)));
        return;
      }

      if (s.source case final ExternalSwapSource source) {
        emit(SwapAwaitingExternalSend(trade: trade, source: source));
      } else if (s.source case final InternalSwapSource source) {
        final generatingState = SwapGeneratingTransaction(trade: trade, source: source);
        emit(generatingState);

        try {
          final tx = await _createSwapTransaction(trade, s.isSwapAll);
          emit(SwapAwaitingSend(trade: trade, transaction: tx, source: source));
        } catch (e) {
          emit(generatingState.toError(e));
        }
      }
    }
  }

  Future<PendingTransaction> _createSwapTransaction(Trade trade, bool isSendAll) async {
    if (_registry.getProvider(trade.provider) case final TransactionCreationExchangeProvider p) {
      return  p.createTransaction(_appStore.wallet!, trade);
    } else {
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
  }

  Future<void> _onSendConfirmed(SendConfirmed event, Emitter<SwapState> emit) async {
    if (state case final SwapStateWithTransaction s) {
      emit(SwapSending(trade: s.trade, transaction: s.transaction, source: s.source));
      try {
        await _transactionService.commitTransaction(s.transaction);
        emit(
          SwapTransactionCommitted(trade: s.trade, transaction: s.transaction, source: s.source),
        );
      } catch (e) {
        emit(s.toError(e));
      }
    }
  }
}
