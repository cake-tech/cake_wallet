import "dart:async";

import "package:bloc/bloc.dart";
import "package:bloc_concurrency/bloc_concurrency.dart";
import "package:cake_wallet/core/active_wallet_service.dart";
import "package:cake_wallet/core/address_service.dart";
import "package:cake_wallet/core/address_types.dart";
import "package:cake_wallet/core/fiat_rate_service.dart";
import "package:cake_wallet/entities/auto_generate_subaddress_status.dart";
import "package:cake_wallet/entities/fiat_currency.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/currency.dart";
import "package:cw_core/payment_uris.dart";
import "package:cw_core/receive_page_option.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_type.dart";
import "package:equatable/equatable.dart";
part "receive_event.dart";
part "receive_state.dart";

class ReceiveBloc extends Bloc<ReceiveEvent, ReceiveState> {
  ReceiveBloc({
    required this.addressService,
    required this.fiatRateService,
    required this.activeWalletService,
    bool lightningMode = false,
    CryptoCurrency? initialToken,
  })  : _lightningMode = lightningMode,
        super(const ReceiveLoading()) {
    on<ReceiveOpened>(_onOpened, transformer: restartable());
    on<AmountChanged>(_onAmountChanged, transformer: restartable());
    on<InputCurrencySelected>(_onInputCurrencySelected, transformer: restartable());
    on<TokenPresetSelected>(_onTokenPresetSelected, transformer: sequential());
    on<AddressTypeSelected>(_onAddressTypeSelected, transformer: sequential());
    on<AddressRotated>(_onAddressRotated, transformer: droppable());
    on<LabelSubmitted>(_onLabelSubmitted, transformer: sequential());
    on<InfoboxDismissed>(_onInfoboxDismissed, transformer: droppable());
    on<AddressesPageClosed>(_onAddressesPageClosed);
    on<_WalletChanged>(_onWalletChanged, transformer: restartable());
    on<_FiatRateChanged>(_onFiatRateChanged);
    on<_PayjoinEndpointChanged>(_onPayjoinEndpointChanged);

    _walletSub = activeWalletService.walletChanges.listen((_) {
      if (!isClosed) {
        add(const _WalletChanged());
      }
    });
    _rateSub = fiatRateService.rateChanges.listen((_) {
      if (!isClosed) {
        add(const _FiatRateChanged());
      }
    });
    _payjoinSub = addressService.payjoinEndpointChanges.listen((_) {
      if (!isClosed) {
        add(const _PayjoinEndpointChanged());
      }
    });

    add(ReceiveOpened(lightningMode: lightningMode, initialToken: initialToken));
  }

  final AddressService addressService;
  final FiatRateService fiatRateService;
  final ActiveWalletService activeWalletService;
  bool _lightningMode;

  late final StreamSubscription<WalletBase> _walletSub;
  late final StreamSubscription<void> _rateSub;
  late final StreamSubscription<String?> _payjoinSub;

  @override
  Future<void> close() async {
    await _walletSub.cancel();
    await _rateSub.cancel();
    await _payjoinSub.cancel();
    return super.close();
  }

  Future<void> _onOpened(ReceiveOpened event, Emitter<ReceiveState> emit) async {
    emit(const ReceiveLoading());
    _lightningMode = event.lightningMode;

    try {
      await addressService.applyOpenDefaults(lightningMode: _lightningMode);
      addressService.applyAutoGenerateOverride();

      if (isClosed) {
        return;
      }
      final effectiveInitialToken = _lightningMode ? CryptoCurrency.btcln : event.initialToken;
      emit(_buildLoaded(initialToken: effectiveInitialToken));
    } catch (e) {
      printV("ReceiveBloc _onOpened failed: $e");
      if (!isClosed) {
        emit(const ReceiveFailure(ReceiveFailureCode.addressListUnavailable));
      }
    }
  }

  Future<void> _onAmountChanged(AmountChanged event, Emitter<ReceiveState> emit) async {
    final initial = state;
    if (initial is! ReceiveLoaded) {
      return;
    }

    final raw = event.raw.replaceAll(",", ".");
    final receiveCrypto = _receiveCryptoCurrency(initial);

    Money? requestedAmount;
    Money? fiatEquivalent;

    if (raw.isEmpty) {
      requestedAmount = null;
      fiatEquivalent = null;
    } else if (initial.inputCurrency is FiatCurrency) {
      final fiatCurrency = initial.inputCurrency as FiatCurrency;
      final fiatMoney = fiatCurrency.tryParseAmount(raw);
      if (fiatMoney != null) {
        await fiatRateService.ensureRateFor(receiveCrypto, fiatCurrency);
        if (isClosed) {
          return;
        }
        if (state case final ReceiveLoaded current when current.walletId != initial.walletId) {
          return;
        }
        requestedAmount = fiatRateService.convertFromFiat(fiatMoney, receiveCrypto);
        if (requestedAmount != null) {
          fiatEquivalent = fiatMoney;
        }
      }
    } else {
      // Use the input token currency for the sats check, not the BTCLN→BTC
      // substituted receiveCrypto. Under `satoshiForLightning` display mode
      // useSatoshi(BTCLN) is true but useSatoshi(BTC) is false, so passing BTC
      // here would treat "1235" as 1235 BTC (123.5B sats) instead of 1235 sats
      // and each modal round-trip would multiply the amount by 10^8.
      final inputCrypto = initial.tokenCurrency ?? addressService.walletCurrency;
      final canonical = addressService.canonicalCryptoAmount(raw, inputCrypto);
      requestedAmount = receiveCrypto.tryParseAmount(canonical);
      if (requestedAmount != null) {
        fiatEquivalent =
            fiatRateService.convertToFiat(requestedAmount, fiatRateService.defaultFiat);
      }
    }

    final rawCryptoForUri = requestedAmount?.toStringWithPrecision() ?? "";

    if (state case final ReceiveLoaded loaded when loaded.isLightning) {
      emit(
        loaded.copyWith(
          requestedAmount: requestedAmount,
          clearRequestedAmount: requestedAmount == null,
          fiatEquivalent: fiatEquivalent,
          clearFiatEquivalent: fiatEquivalent == null,
          fetchingInvoice: true,
        ),
      );

      try {
        final uri = await addressService.fetchPaymentRequestUri(
          rawAmount: rawCryptoForUri,
          token: loaded.tokenCurrency,
        );
        if (isClosed) {
          return;
        }
        if (state case final ReceiveLoaded loaded when loaded.walletId == initial.walletId) {
          emit(loaded.copyWith(paymentUri: uri, fetchingInvoice: false));
        }
      } catch (e) {
        printV("ReceiveBloc lightning invoice fetch failed: $e");
        if (isClosed) {
          return;
        }
        if (state case final ReceiveLoaded loaded when loaded.walletId == initial.walletId) {
          emit(loaded.copyWith(
            fetchingInvoice: false,
            failureCode: ReceiveFailureCode.invoiceFetchFailed,
          ));
        }
      }
    } else if (state case final ReceiveLoaded loaded) {
      final uri = addressService.buildPaymentUri(
        rawAmount: rawCryptoForUri,
        token: loaded.tokenCurrency,
      );
      emit(
        loaded.copyWith(
          requestedAmount: requestedAmount,
          clearRequestedAmount: requestedAmount == null,
          fiatEquivalent: fiatEquivalent,
          clearFiatEquivalent: fiatEquivalent == null,
          paymentUri: uri,
        ),
      );
    }
  }

  Future<void> _onInputCurrencySelected(
    InputCurrencySelected event,
    Emitter<ReceiveState> emit,
  ) async {
    final initial = state;
    if (initial is! ReceiveLoaded) {
      return;
    }

    emit(
      initial.copyWith(
        inputCurrency: event.currency,
        inputUsesSats: addressService.useSatoshi(event.currency),
      ),
    );

    if (event.currency is FiatCurrency && event.currency != fiatRateService.defaultFiat) {
      await fiatRateService.ensureRateFor(
        _receiveCryptoCurrency(initial),
        event.currency as FiatCurrency,
      );
    }

    if (isClosed) {
      return;
    }
    if (state case final ReceiveLoaded loaded
        when loaded.walletId == initial.walletId && loaded.requestedAmount != null) {
      final displayFiat = event.currency is FiatCurrency
          ? event.currency as FiatCurrency
          : fiatRateService.defaultFiat;
      final newFiat = fiatRateService.convertToFiat(loaded.requestedAmount!, displayFiat);
      emit(loaded.copyWith(fiatEquivalent: newFiat, clearFiatEquivalent: newFiat == null));
    }
  }

  Future<void> _onTokenPresetSelected(
    TokenPresetSelected event,
    Emitter<ReceiveState> emit,
  ) async {
    final loaded = state;
    if (loaded is! ReceiveLoaded) {
      return;
    }

    final token = _resolveTokenCurrency(event.token);
    final receiveCrypto = token ?? addressService.walletCurrency;

    final newInputCurrency =
        loaded.inputCurrency is CryptoCurrency ? receiveCrypto : loaded.inputCurrency;

    final uri = addressService.buildPaymentUri(rawAmount: "", token: token);

    emit(
      loaded.copyWith(
        tokenCurrency: token,
        clearTokenCurrency: token == null,
        inputCurrency: newInputCurrency,
        inputUsesSats: addressService.useSatoshi(newInputCurrency),
        receiveUsesSats: addressService.useSatoshi(receiveCrypto),
        paymentUri: uri,
        clearRequestedAmount: true,
        clearFiatEquivalent: true,
      ),
    );

    if (newInputCurrency is FiatCurrency) {
      await fiatRateService.ensureRateFor(receiveCrypto, newInputCurrency);
    }
  }

  Future<void> _onAddressTypeSelected(
    AddressTypeSelected event,
    Emitter<ReceiveState> emit,
  ) async {
    final initial = state;
    if (initial is! ReceiveLoaded) {
      return;
    }

    if (_isAnonpayOption(event.option)) {
      return;
    }

    emit(initial.copyWith(isChangingAddressType: true, clearFailureCode: true));
    try {
      await addressService.setAddressType(event.option);
    } catch (e) {
      printV("ReceiveBloc setAddressType failed: $e");
      if (isClosed) {
        return;
      }
      if (state case final ReceiveLoaded loaded when loaded.walletId == initial.walletId) {
        emit(loaded.copyWith(
          isChangingAddressType: false,
          failureCode: ReceiveFailureCode.addressListUnavailable,
        ));
      }
      return;
    }

    if (isClosed) {
      return;
    }
    if (state case final ReceiveLoaded loaded when loaded.walletId == initial.walletId) {
      final newAddress = _currentAddressEntry();
      final newUri = addressService.buildPaymentUri(
        rawAmount: loaded.requestedAmount?.toStringWithPrecision() ?? "",
        token: loaded.tokenCurrency,
      );
      final isCurrentRequestLightning = newUri is LightningPaymentRequest;

      var nextToken = loaded.tokenCurrency;
      var nextInput = loaded.inputCurrency;
      var clearToken = false;

      if (isCurrentRequestLightning && !loaded.isLightning) {
        nextToken = CryptoCurrency.btcln;
        if (loaded.inputCurrency is CryptoCurrency) {
          nextInput = CryptoCurrency.btcln;
        }
      } else if (!isCurrentRequestLightning && loaded.isLightning) {
        if (loaded.tokenCurrency == CryptoCurrency.btcln) {
          nextToken = null;
          clearToken = true;
        }
        if (loaded.inputCurrency == CryptoCurrency.btcln) {
          nextInput = addressService.walletCurrency;
        }
      }

      _lightningMode = isCurrentRequestLightning;

      final nextReceiveCrypto = nextToken ?? addressService.walletCurrency;
      emit(
        loaded.copyWith(
          addressType: event.option,
          addressEntry: newAddress,
          paymentUri: newUri,
          tokenCurrency: nextToken,
          clearTokenCurrency: clearToken,
          inputCurrency: nextInput,
          inputUsesSats: addressService.useSatoshi(nextInput),
          receiveUsesSats: addressService.useSatoshi(nextReceiveCrypto),
          isSilentPayments: addressService.isSilentPayments,
          isLightning: isCurrentRequestLightning,
          isZCashTransparent: addressService.isZCashTransparent,
          walletType: addressService.walletType,
          isChangingAddressType: false,
        ),
      );
    }
  }

  Future<void> _onAddressRotated(AddressRotated event, Emitter<ReceiveState> emit) async {
    final initial = state;
    if (initial is! ReceiveLoaded) {
      return;
    }

    emit(initial.copyWith(isRotatingAddress: true, clearFailureCode: true));

    try {
      await addressService.rotateAddress();
      if (isClosed) {
        return;
      }
      if (state case final ReceiveLoaded loaded when loaded.walletId == initial.walletId) {
        emit(
          loaded.copyWith(
            addressEntry: _currentAddressEntry(),
            paymentUri: addressService.buildPaymentUri(
              rawAmount: loaded.requestedAmount?.toStringWithPrecision() ?? "",
              token: loaded.tokenCurrency,
            ),
            isRotatingAddress: false,
          ),
        );
      }
    } catch (e) {
      printV("ReceiveBloc rotate failed: $e");
      if (isClosed) {
        return;
      }
      if (state case final ReceiveLoaded loaded when loaded.walletId == initial.walletId) {
        emit(loaded.copyWith(
          isRotatingAddress: false,
          failureCode: ReceiveFailureCode.addressListUnavailable,
        ));
      }
    }
  }

  Future<void> _onLabelSubmitted(LabelSubmitted event, Emitter<ReceiveState> emit) async {
    final initial = state;
    if (initial is! ReceiveLoaded) {
      return;
    }

    try {
      await addressService.setLabel(initial.addressEntry.address, event.label);
    } catch (e) {
      printV("ReceiveBloc setLabel failed: $e");
      if (isClosed) {
        return;
      }
      if (state case final ReceiveLoaded loaded when loaded.walletId == initial.walletId) {
        emit(loaded.copyWith(failureCode: ReceiveFailureCode.addressListUnavailable));
      }
      return;
    }
    if (isClosed) {
      return;
    }
    if (state case final ReceiveLoaded loaded when loaded.walletId == initial.walletId) {
      emit(loaded.copyWith(addressEntry: _currentAddressEntry()));
    }
  }

  Future<void> _onInfoboxDismissed(InfoboxDismissed event, Emitter<ReceiveState> emit) async {
    final initial = state;
    if (initial is! ReceiveLoaded || initial.infoboxDismissed) {
      return;
    }

    try {
      await addressService.dismissInfobox();
    } catch (e) {
      printV("ReceiveBloc dismissInfobox failed: $e");
      return;
    }
    if (isClosed) {
      return;
    }
    if (state case final ReceiveLoaded loaded when loaded.walletId == initial.walletId) {
      emit(loaded.copyWith(infoboxDismissed: true));
    }
  }

  Future<void> _onAddressesPageClosed(
    AddressesPageClosed event,
    Emitter<ReceiveState> emit,
  ) async {
    final loaded = state;
    if (loaded is! ReceiveLoaded) {
      return;
    }

    emit(
      loaded.copyWith(
        addressEntry: _currentAddressEntry(),
        paymentUri: addressService.buildPaymentUri(
          rawAmount: loaded.requestedAmount?.toStringWithPrecision() ?? "",
          token: loaded.tokenCurrency,
        ),
      ),
    );
  }

  Future<void> _onWalletChanged(_WalletChanged event, Emitter<ReceiveState> emit) async {
    emit(const ReceiveLoading());
    try {
      _lightningMode = false;
      await addressService.applyOpenDefaults(lightningMode: _lightningMode);
      addressService.applyAutoGenerateOverride();

      if (isClosed) {
        return;
      }
      emit(_buildLoaded(initialToken: null));
    } catch (e) {
      printV("ReceiveBloc _onWalletChanged failed: $e");
      if (!isClosed) {
        emit(const ReceiveFailure(ReceiveFailureCode.addressListUnavailable));
      }
    }
  }

  Future<void> _onFiatRateChanged(_FiatRateChanged event, Emitter<ReceiveState> emit) async {
    final loaded = state;
    if (loaded is! ReceiveLoaded) {
      return;
    }
    if (loaded.inputCurrency is FiatCurrency && loaded.fiatEquivalent != null) {
      final receiveCrypto = _receiveCryptoCurrency(loaded);
      final newCrypto = fiatRateService.convertFromFiat(loaded.fiatEquivalent!, receiveCrypto);
      final rawCryptoForUri = newCrypto?.toStringWithPrecision() ?? "";
      final uri = addressService.buildPaymentUri(
        rawAmount: rawCryptoForUri,
        token: loaded.tokenCurrency,
      );
      emit(
        loaded.copyWith(
          requestedAmount: newCrypto,
          clearRequestedAmount: newCrypto == null,
          paymentUri: uri,
        ),
      );
      return;
    }

    if (loaded.requestedAmount == null) {
      return;
    }
    final newFiat =
        fiatRateService.convertToFiat(loaded.requestedAmount!, fiatRateService.defaultFiat);
    emit(loaded.copyWith(fiatEquivalent: newFiat, clearFiatEquivalent: newFiat == null));
  }

  Future<void> _onPayjoinEndpointChanged(
    _PayjoinEndpointChanged event,
    Emitter<ReceiveState> emit,
  ) async {
    final loaded = state;
    if (loaded is! ReceiveLoaded) {
      return;
    }

    final endpoint = addressService.payjoinEndpoint;
    final uri = addressService.buildPaymentUri(
      rawAmount: loaded.requestedAmount?.toStringWithPrecision() ?? "",
      token: loaded.tokenCurrency,
    );
    if (endpoint.isEmpty) {
      emit(loaded.copyWith(clearPayjoinEndpoint: true, paymentUri: uri));
    } else {
      emit(loaded.copyWith(payjoinEndpoint: endpoint, paymentUri: uri));
    }
  }

  ReceiveLoaded _buildLoaded({CryptoCurrency? initialToken}) {
    final tokenCurrency = _resolveTokenCurrency(initialToken);
    final inputCurrency = tokenCurrency ?? addressService.walletCurrency;
    final endpoint = addressService.payjoinEndpoint;
    final uri = addressService.buildPaymentUri(rawAmount: "", token: tokenCurrency);

    final receiveCrypto = tokenCurrency ?? addressService.walletCurrency;
    return ReceiveLoaded(
      addressEntry: _currentAddressEntry(),
      addressType: addressService.selectedAddressType,
      addressTypeOptions: addressService.addressTypeOptions,
      inputCurrency: inputCurrency,
      tokenCurrency: tokenCurrency,
      receivableTokens: addressService.receivableTokens,
      requestedAmount: null,
      fiatEquivalent: null,
      infoboxDismissed: addressService.infoboxDismissed,
      payjoinEndpoint: endpoint.isEmpty ? null : endpoint,
      fetchingInvoice: false,
      isRotatingAddress: false,
      paymentUri: uri,
      isSilentPayments: addressService.isSilentPayments,
      isLightning: uri is LightningPaymentRequest,
      autoGenerateSubaddressStatus: addressService.autoGenerateSubaddressStatus,
      isZCashTransparent: addressService.isZCashTransparent,
      inputUsesSats: addressService.useSatoshi(inputCurrency),
      receiveUsesSats: addressService.useSatoshi(receiveCrypto),
      walletId: addressService.walletId,
      walletType: addressService.walletType,
      walletCurrency: addressService.walletCurrency,
      hasTokensList: addressService.hasTokensList,
    );
  }

  AddressEntry _currentAddressEntry() {
    final current = addressService.currentAddress;
    final entries = addressService.computeAddressList().expand((g) => g.entries);
    return entries.firstWhere(
      (e) => e.address == current,
      orElse: () => AddressEntry(address: current),
    );
  }

  CryptoCurrency _receiveCryptoCurrency(ReceiveLoaded current) {
    var currency = current.tokenCurrency ?? addressService.walletCurrency;
    if (currency == CryptoCurrency.btcln) {
      currency = CryptoCurrency.btc;
    }
    return currency;
  }

  CryptoCurrency? _resolveTokenCurrency(CryptoCurrency? preset) {
    if (preset == null) {
      return null;
    }
    if (preset == addressService.walletCurrency) {
      return null;
    }
    return preset;
  }

  bool _isAnonpayOption(ReceivePageOption option) =>
      option == ReceivePageOption.anonPayInvoice || option == ReceivePageOption.anonPayDonationLink;
}
