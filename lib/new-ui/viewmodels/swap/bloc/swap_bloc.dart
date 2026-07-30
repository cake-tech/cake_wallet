import "package:bloc/bloc.dart";
import "package:bloc_concurrency/bloc_concurrency.dart";
import "package:cake_wallet/entities/fiat_currency.dart";
import "package:cake_wallet/exchange/exchange_provider_description.dart";
import "package:cake_wallet/exchange/trade.dart";
import "package:cake_wallet/exchange/trade_request.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/currency_provider.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/provider_registry.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/rates/rate_cubit.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/swap_address.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/swap_amount.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/swap_source.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cake_wallet/utils/list_extension.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/payment_uris.dart";
import "package:cw_core/pending_transaction.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:meta/meta.dart";

part "swap_event.dart";

part "swap_state.dart";

class SwapBloc extends Bloc<SwapEvent, SwapState> {
  SwapBloc({
    required this.rateCubit,
    required this.currencyStore,
    required SwapAmountFactory calculator,
    required ExchangeProviderRegistry registry,
    required SettingsStore settingsStore,
    required WalletBase wallet,
  })  : _amountFactory = calculator,
        _registry = registry,
        _settingsStore = settingsStore,
        _wallet = wallet,
        super(const SwapStateNotLoaded()) {
    on<_Init>(_init);
    on<SourceChanged>(_onSourceChanged, transformer: restartable());
    on<PayoutAddressChanged>(_onPayoutAddressChanged, transformer: restartable());
    on<DepositAmountChanged>(_onDepositAmountChanged, transformer: restartable());
    on<PayoutAmountChanged>(_onPayoutAmountChanged, transformer: restartable());
    on<RatesLoadStarted>(_onRatesLoadStarted, transformer: droppable());
    on<DepositCurrencyChanged>(_onDepositCurrencyChanged, transformer: restartable());
    on<PayoutCurrencyChanged>(_onPayoutCurrencyChanged, transformer: restartable());
    on<SwapDirectionReversed>(_onSwapDirectionReversed, transformer: sequential());
    on<ForcedProviderSelected>(_onForcedProviderSelected, transformer: restartable());
    on<ProviderToggled>(_onProviderToggled, transformer: sequential());
    on<FixedRateToggled>(_onFixedRateToggled, transformer: sequential());
    on<FiatCurrencyChanged>(_onFiatCurrencyChanged);
    on<ForceDecentralizedExchangesToggled>(_onForceDecentralizedExchangesToggled, transformer: sequential());
    on<SwapInitiated>(_onSwapInitiated);
    on<SendConfirmed>(_onSendConfirmed);
    add(_Init());
  }

  final SettingsStore _settingsStore;
  final WalletBase _wallet;
  final ExchangeProviderRegistry _registry;
  final RateCubit rateCubit;
  final SwapAmountFactory _amountFactory;
  final SwapCurrencyStore currencyStore;

  FiatCurrency get fiat => _settingsStore.fiatCurrency;

  Future<void> _reloadRates() async {
    if (state case final SwapStateWithInputs s) {
      await rateCubit.fetchRates(
        s.usableProviders,
        from: s.depositAmount.cryptoAmount,
        to: s.payoutAmount.currency,
        isFixedRate: s.isFixedRate,
      );
    }
  }

  Future<void> _init(_Init event, Emitter<SwapState> emit) async {
    final initialDepositCurrency = _wallet.currency;
    final initialPayoutCurrency =
        initialDepositCurrency == CryptoCurrency.xmr ? CryptoCurrency.btc : CryptoCurrency.xmr;

    final initialDepositAmount = SwapAmount(
      cryptoAmount: Money.zero(initialDepositCurrency),
      fiatAmount: Money.zero(_settingsStore.fiatCurrency),
    );
    final initialPayoutAmount = SwapAmount(
      cryptoAmount: Money.zero(initialPayoutCurrency),
      fiatAmount: Money.zero(_settingsStore.fiatCurrency),
    );

    emit(
      SwapInputState(
        depositAmount: initialDepositAmount,
        payoutAmount: initialPayoutAmount,
        source: InternalSwapSource(_wallet.walletInfo),
        payoutAddress: null,
        isFixedRate: false,
        availableProviders: _registry.allProviders,
        enabledProviders: _registry.allProviders,
        forceDecentralizedProviders: _settingsStore.forceDecentralizedExchanges,
      ),
    );
  }

  void _onSourceChanged(SourceChanged event, Emitter<SwapState> emit) {
    if (state case final SwapInputState s) {
      emit(s.copyWith(source: event.newSource));
    }
  }

  void _onPayoutAddressChanged(PayoutAddressChanged event, Emitter<SwapState> emit) {
    if (state case final SwapInputState s) {
      emit(s.copyWith(payoutAddress: event.newAddress));
    }
  }

  Future<void> _onDepositAmountChanged(DepositAmountChanged event, Emitter<SwapState> emit) async {
    if (state case final SwapInputState s) {
      final newDepositAmount =
      await _amountFactory.getSwapAmount(event.newAmount, s.depositAmount.currency);

      final Money newPayoutCryptoAmount;
      if (rateCubit.state case final RatesLoaded l) {
        newPayoutCryptoAmount = l.rates.max.rate.convert(newDepositAmount.cryptoAmount);
      } else {
        newPayoutCryptoAmount = Money.zero(s.payoutAmount.currency);
      }

      final newPayoutAmount =
          await _amountFactory.getSwapAmount(newPayoutCryptoAmount, s.payoutAmount.currency);

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
      final newPayoutAmount =
      await _amountFactory.getSwapAmount(event.newAmount, s.payoutAmount.currency);

      final Money newDepositCryptoAmount;
      if (rateCubit.state case final RatesLoaded l) {
        newDepositCryptoAmount = l.rates.max.rate.convert(newPayoutAmount.cryptoAmount);
      } else {
        newDepositCryptoAmount = Money.zero(s.depositAmount.currency);
      }

      final newDepositAmount =
      await _amountFactory.getSwapAmount(newDepositCryptoAmount, s.depositAmount.currency);

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

  Future<void> _onRatesLoadStarted(RatesLoadStarted event, Emitter<SwapState> emit) async {
    await _reloadRates();
    if (state case final SwapInputState s) {
      if(rateCubit.state case final RatesLoaded rs) {
        final SwapAmount newDepositAmount;
        final SwapAmount newPayoutAmount;
        if(s.isFixedRate) {
          newDepositAmount = await _amountFactory.getSwapAmount(rs.rates.max.rate.convert(s.payoutAmount.cryptoAmount), s.depositAmount.currency);
newPayoutAmount = s.payoutAmount;
        } else {
          newDepositAmount = s.depositAmount;
          newPayoutAmount = await _amountFactory.getSwapAmount(rs.rates.max.rate.convert(s.depositAmount.cryptoAmount), s.payoutAmount.currency);
        }
        emit(s.copyWith(
          depositAmount: newDepositAmount,
          payoutAmount: newPayoutAmount
        ));
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
      if (s.isFixedRate) {
        newDepositAmount =
            await _amountFactory.getSwapAmount(Money.zero(event.newCurrency), event.newCurrency);
        newPayoutAmount = s.payoutAmount;
      } else {
        newDepositAmount = await _amountFactory.getSwapAmount(
          Money(s.depositAmount.cryptoAmount.amount, event.newCurrency),
          event.newCurrency,
        );
        newPayoutAmount = await _amountFactory.getSwapAmount(
          Money.zero(s.payoutAmount.currency),
          s.payoutAmount.currency,
        );
      }

      SwapSource newSource = s.source;
      if(s.source case final InternalSwapSource iss) {
        if(cryptoCurrencyOrTokenToWalletType(event.newCurrency) != iss.sourceWallet.type) {
            newSource = const ExternalSwapSource("");
        }
      }

      emit(
        s.copyWith(
          depositAmount: newDepositAmount,
          payoutAmount: newPayoutAmount,
          source: newSource
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
        newPayoutAmount =
            await _amountFactory.getSwapAmount(Money.zero(event.newCurrency), event.newCurrency);
      }
      emit(
        s.copyWith(
          depositAmount: newDepositAmount,
          payoutAmount: newPayoutAmount,
        ),
      );
      add(RatesLoadStarted());
    }
  }

  Future<void> _onSwapDirectionReversed(
      SwapDirectionReversed event, Emitter<SwapState> emit) async {
    if (state case final SwapInputState s) {
      final SwapAmount newDepositAmount;
      final SwapAmount newPayoutAmount;
      if (s.isFixedRate) {
        newPayoutAmount = s.depositAmount;
        newDepositAmount = await _amountFactory.getSwapAmount(
            Money.zero(s.payoutAmount.currency), s.payoutAmount.currency);
      } else {
        newDepositAmount = s.payoutAmount;
        newPayoutAmount = await _amountFactory.getSwapAmount(
            Money.zero(s.depositAmount.currency), s.depositAmount.currency);
      }
      emit(
        s.copyWith(
          depositAmount: newDepositAmount,
          payoutAmount: newPayoutAmount,
        ),
      );
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
    }
  }

  Future<void> _onFixedRateToggled(FixedRateToggled event, Emitter<SwapState> emit) async {
    if (state case final SwapInputState s) {
      emit(
        s.copyWith(
          isFixedRate: !s.isFixedRate,
        ),
      );
      add(RatesLoadStarted());
    }
  }

  Future<void> _onFiatCurrencyChanged(FiatCurrencyChanged event, Emitter<SwapState> emit) async {
    _settingsStore.fiatCurrency = event.newCurrency;
    if (state case final SwapInputState s) {
      emit(
        s.copyWith(
          depositAmount:
             await _amountFactory.getSwapAmount(s.depositAmount.cryptoAmount, s.depositAmount.currency),
          payoutAmount:
              await _amountFactory.getSwapAmount(s.payoutAmount.cryptoAmount, s.payoutAmount.currency),
        ),
      );
    }
  }

  void _onForceDecentralizedExchangesToggled(ForceDecentralizedExchangesToggled event, Emitter<SwapState> emit) {
    if(state case final SwapInputState s) {
      final newState = !s.forceDecentralizedProviders;
      _settingsStore.forceDecentralizedExchanges = newState;
      emit(s.copyWith(forceDecentralizedProviders: newState));
    }
  }

  Future<void> _onSwapInitiated(SwapInitiated event, Emitter<SwapState> emit) async {
    await _reloadRates();
    final rate = (rateCubit.state as RatesLoaded).rates.max;
    if (state case final SwapStateWithInputs s) {
      final String refundAddress;
      if (s.source case final ExternalSwapSource source) {
        refundAddress = source.refundAddress;
      } else if (s.source case final InternalSwapSource source) {
        if (source.sourceWallet.internalId != _wallet.walletInfo.internalId) {
          // TODO(malik): switch wallet
        }
        refundAddress = _wallet.walletAddresses.addressForExchange;
      } else {
        // SwapSource is abstract and InternalSwapSource and ExternalSwapSource are the only two implementations
        // nonetheless, analyzer won't shut up without this else clause if we have strict type checks enabled
        throw UnsupportedError("should not be reachable");
      }

      final req = TradeRequest(

        refundAddress: refundAddress,
        payoutAddress: s.payoutAddress!,
        depositAmount: s.depositAmount,
        payoutAmount: s.payoutAmount,
        isFixedRate: s.isFixedRate,
      );

      final creatingState = SwapStateCreating(source: s.source,selectedProvider: rate.provider, request: req);
      emit(creatingState);


      try {
        final trade = await _registry.getProvider(rate.provider).createTrade(request: req);
        await trade.save();
        emit(SwapCreated(trade: trade, source: s.source));
      } catch(e) {
        emit(creatingState.toError(e));
      }


    }
  }

  Future<void> _onSendConfirmed(SendConfirmed event, Emitter<SwapState> emit) async {

  }
}
