import "dart:async";

import "package:bloc/bloc.dart";
import "package:bloc_concurrency/bloc_concurrency.dart";
import "package:cake_wallet/core/active_wallet_service.dart";
import "package:cake_wallet/core/address_service.dart";
import "package:cake_wallet/core/address_types.dart";
import "package:cake_wallet/core/fiat_rate_service.dart";
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
    ReceivePageOption? typeOverride,
    CryptoCurrency? initialToken,
  }) : super(const ReceiveLoading()) {
    on<ReceiveOpened>(_onOpened, transformer: restartable());
    on<AmountChanged>(_onAmountChanged, transformer: restartable());
    on<InputCurrencySelected>(_onInputCurrencySelected, transformer: restartable());
    on<TokenPresetSelected>(_onTokenPresetSelected);
    on<AddressTypeSelected>(_onAddressTypeSelected);
    on<AddressRotated>(_onAddressRotated, transformer: droppable());
    on<LabelSubmitted>(_onLabelSubmitted);
    on<InfoboxDismissed>(_onInfoboxDismissed);
    on<AddressesPageClosed>(_onAddressesPageClosed);
    on<_WalletChanged>(_onWalletChanged);
    on<_FiatRateChanged>(_onFiatRateChanged);
    on<_PayjoinEndpointChanged>(_onPayjoinEndpointChanged);

    _walletSub = activeWalletService.walletChanges.listen((_) => add(const _WalletChanged()));
    _rateSub = fiatRateService.rateChanges.listen((_) => add(const _FiatRateChanged()));
    _payjoinSub =
        addressService.payjoinEndpointChanges.listen((_) => add(const _PayjoinEndpointChanged()));

    add(ReceiveOpened(typeOverride: typeOverride, initialToken: initialToken));
  }

  final AddressService addressService;
  final FiatRateService fiatRateService;
  final ActiveWalletService activeWalletService;

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

    try {
      if (event.typeOverride != null && !_isAnonpayOption(event.typeOverride!)) {
        await addressService.setAddressType(event.typeOverride!);
      }

      final loaded = _buildLoaded(initialToken: event.initialToken);
      emit(loaded);
    } catch (e) {
      printV("ReceiveBloc _onOpened failed: $e");
      emit(const ReceiveFailure(ReceiveFailureCode.addressListUnavailable));
    }
  }

  Future<void> _onAmountChanged(AmountChanged event, Emitter<ReceiveState> emit) async {
    final loaded = state;
    if (loaded is! ReceiveLoaded) {
      return;
    }

    final raw = event.raw.replaceAll(",", ".");
    final receiveCrypto = _receiveCryptoCurrency(loaded);

    Money? requestedAmount;
    Money? fiatEquivalent;

    if (raw.isEmpty) {
      requestedAmount = null;
      fiatEquivalent = null;
    } else if (loaded.inputCurrency is FiatCurrency) {
      final fiatCurrency = loaded.inputCurrency as FiatCurrency;
      final fiatMoney = fiatCurrency.tryParseAmount(raw);
      if (fiatMoney != null) {
        await fiatRateService.ensureRateFor(receiveCrypto, fiatCurrency);
        requestedAmount = fiatRateService.convertFromFiat(fiatMoney, receiveCrypto);
        fiatEquivalent = fiatMoney;
      }
    } else {
      requestedAmount = receiveCrypto.tryParseAmount(raw);
      if (requestedAmount != null) {
        fiatEquivalent =
            fiatRateService.convertToFiat(requestedAmount, fiatRateService.defaultFiat);
      }
    }

    final rawCryptoForUri = requestedAmount?.toStringWithPrecision() ?? "";

    if (loaded.isLightning) {
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
        if (state case final ReceiveLoaded loaded) {
          emit(loaded.copyWith(paymentUri: uri, fetchingInvoice: false));
        }
      } catch (e) {
        printV("ReceiveBloc lightning invoice fetch failed: $e");
        if (state case final ReceiveLoaded loaded) {
          emit(loaded.copyWith(fetchingInvoice: false));
        }
      }
    } else {
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
    final loaded = state;
    if (loaded is! ReceiveLoaded) {
      return;
    }

    emit(loaded.copyWith(inputCurrency: event.currency));

    if (event.currency is FiatCurrency && event.currency != fiatRateService.defaultFiat) {
      await fiatRateService.ensureRateFor(
        _receiveCryptoCurrency(loaded),
        event.currency as FiatCurrency,
      );
    }

    if (state case final ReceiveLoaded loaded when loaded.requestedAmount != null) {
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

    final uri = addressService.buildPaymentUri(
      rawAmount: loaded.requestedAmount?.toStringWithPrecision() ?? "",
      token: token,
    );

    emit(
      loaded.copyWith(
        tokenCurrency: token,
        clearTokenCurrency: token == null,
        inputCurrency:
            loaded.inputCurrency is CryptoCurrency ? receiveCrypto : loaded.inputCurrency,
        paymentUri: uri,
      ),
    );
  }

  Future<void> _onAddressTypeSelected(
    AddressTypeSelected event,
    Emitter<ReceiveState> emit,
  ) async {
    final loaded = state;
    if (loaded is! ReceiveLoaded) {
      return;
    }

    if (_isAnonpayOption(event.option)) {
      return;
    }

    await addressService.setAddressType(event.option);

    if (state case final ReceiveLoaded loaded) {
      final newAddress = _currentAddressEntry();
      final newUri = addressService.buildPaymentUri(
        rawAmount: loaded.requestedAmount?.toStringWithPrecision() ?? "",
        token: loaded.tokenCurrency,
      );
      emit(
        loaded.copyWith(
          addressType: event.option,
          addressEntry: newAddress,
          paymentUri: newUri,
          isSilentPayments: addressService.isSilentPayments,
          isLightning: newUri is LightningPaymentRequest,
          isAutoGenerateSubaddressEnabled: addressService.isAutoGenerateSubaddressEnabled,
          walletType: addressService.walletType,
        ),
      );
    }
  }

  Future<void> _onAddressRotated(AddressRotated event, Emitter<ReceiveState> emit) async {
    final loaded = state;
    if (loaded is! ReceiveLoaded) {
      return;
    }

    emit(loaded.copyWith(isRotatingAddress: true));

    try {
      await addressService.rotateAddress();
      if (state case final ReceiveLoaded loaded) {
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
      if (state case final ReceiveLoaded loaded) {
        emit(loaded.copyWith(isRotatingAddress: false));
      }
    }
  }

  Future<void> _onLabelSubmitted(LabelSubmitted event, Emitter<ReceiveState> emit) async {
    final loaded = state;
    if (loaded is! ReceiveLoaded) {
      return;
    }

    await addressService.setLabel(loaded.addressEntry.address, event.label);
    if (state case final ReceiveLoaded loaded) {
      emit(loaded.copyWith(addressEntry: _currentAddressEntry()));
    }
  }

  Future<void> _onInfoboxDismissed(InfoboxDismissed event, Emitter<ReceiveState> emit) async {
    final loaded = state;
    if (loaded is! ReceiveLoaded || loaded.infoboxDismissed) {
      return;
    }

    await addressService.dismissInfobox();
    if (state case final ReceiveLoaded loaded) {
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
    add(const ReceiveOpened());
  }

  Future<void> _onFiatRateChanged(_FiatRateChanged event, Emitter<ReceiveState> emit) async {
    final loaded = state;
    if (loaded is! ReceiveLoaded || loaded.requestedAmount == null) {
      return;
    }

    final displayFiat = loaded.inputCurrency is FiatCurrency
        ? loaded.inputCurrency as FiatCurrency
        : fiatRateService.defaultFiat;
    final newFiat = fiatRateService.convertToFiat(loaded.requestedAmount!, displayFiat);
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
    emit(
      loaded.copyWith(
        payjoinEndpoint: endpoint.isEmpty ? null : endpoint,
        clearPayjoinEndpoint: endpoint.isEmpty,
      ),
    );
  }

  ReceiveLoaded _buildLoaded({CryptoCurrency? initialToken}) {
    final tokenCurrency = _resolveTokenCurrency(initialToken);
    final inputCurrency = tokenCurrency ?? addressService.walletCurrency;
    final endpoint = addressService.payjoinEndpoint;
    final uri = addressService.buildPaymentUri(rawAmount: "", token: tokenCurrency);

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
      hasAccounts: addressService.hasAccounts,
      accountLabel: addressService.currentAccount?.label,
      isSilentPayments: addressService.isSilentPayments,
      isLightning: uri is LightningPaymentRequest,
      isBitcoinViewOnly: addressService.isBitcoinViewOnly,
      isAutoGenerateSubaddressEnabled: addressService.isAutoGenerateSubaddressEnabled,
      walletType: addressService.walletType,
    );
  }

  AddressEntry _currentAddressEntry() {
    final current = addressService.currentAddress;
    final entries = addressService.computeAddressList().expand((g) => g.entries);
    return entries.firstWhere(
      (e) => e.address == current,
      orElse: () => AddressEntry(address: current, isPrimary: true),
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
    if (preset == addressService.walletCurrency || preset == CryptoCurrency.btcln) {
      return null;
    }
    return preset;
  }

  bool _isAnonpayOption(ReceivePageOption option) =>
      option == ReceivePageOption.anonPayInvoice || option == ReceivePageOption.anonPayDonationLink;
}
