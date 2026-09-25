import "dart:async";

import "package:bloc/bloc.dart";
import "package:bloc_concurrency/bloc_concurrency.dart";
import "package:bloc_presentation/bloc_presentation.dart";
import "package:cake_wallet/core/active_wallet_service.dart";
import "package:cake_wallet/core/address_service.dart";
import "package:cake_wallet/core/address_types.dart";
import "package:cake_wallet/core/fiat_rate_service.dart";
import "package:cake_wallet/entities/auto_generate_subaddress_status.dart";
import "package:cake_wallet/entities/fiat_currency.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/utils/qr_util.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/currency.dart";
import "package:cw_core/payment_uris.dart";
import "package:cw_core/receive_page_option.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_type.dart";
import "package:equatable/equatable.dart";
import "package:flutter/foundation.dart";

part "receive_event.dart";
part "receive_presentation.dart";
part "receive_state.dart";

class ReceiveBloc extends Bloc<ReceiveEvent, ReceiveState>
    with BlocPresentationMixin<ReceiveState, ReceivePresentation> {
  ReceiveBloc({
    required this.addressService,
    required this.fiatRateService,
    required this.activeWalletService,
    CryptoCurrency? initialToken,
  })  : _initialToken = initialToken,
        super(const ReceiveLoading()) {
    on<Init>(_init, transformer: restartable());
    on<AmountChanged>(_onAmountChanged, transformer: restartable());
    on<InputCurrencySelected>(_onInputCurrencySelected, transformer: restartable());
    on<TokenSelected>(_onTokenSelected, transformer: sequential());
    on<AddressTypeSelected>(_onAddressTypeSelected, transformer: sequential());
    on<AddressRotated>(_onAddressRotated, transformer: droppable());
    on<LabelSubmitted>(_onLabelSubmitted, transformer: sequential());
    on<InfoboxDismissed>(_onInfoboxDismissed, transformer: droppable());
    on<AddressesPageClosed>(_onAddressesPageClosed, transformer: sequential());
    on<_WalletChanged>(_onWalletChanged, transformer: restartable());
    on<_FiatRateChanged>(_onFiatRateChanged, transformer: sequential());
    on<_PayjoinEndpointChanged>(_onPayjoinEndpointChanged, transformer: sequential());

    _walletSub = activeWalletService.walletChanges.listen((_) {
      if (!isClosed) {
        add(const _WalletChanged());
      }
    });
    _rateSub = fiatRateService.rateChanges.listen((fiat) {
      if (!isClosed) {
        add(_FiatRateChanged(fiat));
      }
    });
    _payjoinSub = addressService.payjoinEndpointChanges.listen((_) {
      if (!isClosed) {
        add(const _PayjoinEndpointChanged());
      }
    });

    add(const Init());
  }

  final AddressService addressService;
  final FiatRateService fiatRateService;
  final ActiveWalletService activeWalletService;
  final CryptoCurrency? _initialToken;

  late final StreamSubscription<WalletBase> _walletSub;
  late final StreamSubscription<FiatCurrency> _rateSub;
  late final StreamSubscription<String?> _payjoinSub;

  AutoGenerateSubaddressStatus get autoGenerateSubaddressStatus =>
      addressService.autoGenerateSubaddressStatus;

  @override
  Future<void> close() async {
    await _walletSub.cancel();
    await _rateSub.cancel();
    await _payjoinSub.cancel();
    return super.close();
  }

  Future<void> _init(Init event, Emitter<ReceiveState> emit) async {
    emit(const ReceiveLoading());

    try {
      final initialWalletId = addressService.wallet.id;
      await addressService.applyOpenDefaults(
        lightningMode: _initialToken == CryptoCurrency.btcln,
      );
      addressService.applyAutoGenerateOverride();

      if (isClosed) {
        return;
      }

      if (addressService.wallet.id != initialWalletId) {
        return;
      }

      emit(_buildLoaded(initialToken: _initialToken));
    } catch (e) {
      printV("ReceiveBloc _init failed: $e");
      if (!isClosed) {
        emit(const ReceiveFailure());
      }
    }
  }

  Future<void> _onAmountChanged(AmountChanged event, Emitter<ReceiveState> emit) async {
    final initial = state;
    if (initial is! ReceiveLoaded) {
      return;
    }

    final amount = event.amount;
    Money? requestedAmount;
    Money? fiatEquivalent;

    if (amount case Money(currency: final FiatCurrency fiat)) {
      await fiatRateService.ensureRateFor(initial.cryptoCurrency, fiat);
      if (isClosed) {
        return;
      }
      if (state case final ReceiveLoaded current when current.walletId != initial.walletId) {
        return;
      }
      requestedAmount = fiatRateService.convert(amount, initial.cryptoCurrency);
      if (requestedAmount == null) {
        if (state case final ReceiveLoaded loaded when loaded.walletId == initial.walletId) {
          emit(
            loaded.copyWith(
              requestedAmount: () => null,
              fiatEquivalent: () => null,
              paymentUri: loaded.isLightning
                  ? null
                  : addressService.buildPaymentUri(token: loaded.tokenCurrency),
            ),
          );
          emitPresentation(const ReceiveFiatRateUnavailable());
        }
        return;
      }
      fiatEquivalent = amount;
    } else if (amount != null) {
      requestedAmount = amount;
      fiatEquivalent = fiatRateService.convert(amount, fiatRateService.currentFiat);
    }

    if (state case final ReceiveLoaded loaded when loaded.isLightning) {
      emit(
        loaded.copyWith(
          requestedAmount: () => requestedAmount,
          fiatEquivalent: () => fiatEquivalent,
          isFetchingInvoice: true,
        ),
      );

      await _fetchLightningInvoice(
        emit,
        walletId: initial.walletId,
        amount: requestedAmount,
      );
    } else if (state case final ReceiveLoaded loaded) {
      final uri = addressService.buildPaymentUri(
        amount: requestedAmount,
        token: loaded.tokenCurrency,
      );
      emit(
        loaded.copyWith(
          requestedAmount: () => requestedAmount,
          fiatEquivalent: () => fiatEquivalent,
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

    final fiat = switch (event.currency) {
      final FiatCurrency selected => selected,
      _ => null,
    };
    emit(initial.copyWith(fiatCurrency: () => fiat));

    if (fiat != null && fiat != fiatRateService.currentFiat) {
      await fiatRateService.ensureRateFor(initial.cryptoCurrency, fiat);
    }

    if (isClosed) {
      return;
    }
    if (state case final ReceiveLoaded loaded
        when loaded.walletId == initial.walletId && loaded.requestedAmount != null) {
      final newFiat =
          fiatRateService.convert(loaded.requestedAmount!, fiat ?? fiatRateService.currentFiat);
      emit(loaded.copyWith(fiatEquivalent: () => newFiat));
    }
  }

  Future<void> _onTokenSelected(
    TokenSelected event,
    Emitter<ReceiveState> emit,
  ) async {
    final loaded = state;
    if (loaded is! ReceiveLoaded) {
      return;
    }

    final crypto = event.token ?? loaded.walletCurrency;
    if (crypto != loaded.walletCurrency && !loaded.receivableTokens.contains(crypto)) {
      return;
    }

    final next = loaded.copyWith(
      cryptoCurrency: crypto,
      requestedAmount: () => null,
      fiatEquivalent: () => null,
    );
    emit(next.copyWith(paymentUri: addressService.buildPaymentUri(token: next.tokenCurrency)));

    if (loaded.fiatCurrency != null) {
      await fiatRateService.ensureRateFor(crypto, loaded.fiatCurrency!);
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

    emit(initial.copyWith(isChangingAddressType: true));
    try {
      await addressService.setAddressType(event.option);
    } catch (e) {
      printV("ReceiveBloc setAddressType failed: $e");
      _failAddressTypeChange(emit, initial.walletId);
      return;
    }

    if (isClosed) {
      return;
    }
    if (state case final ReceiveLoaded loaded when loaded.walletId == initial.walletId) {
      Money? invoiceAmountToFetch;
      try {
        final newUri = addressService.buildPaymentUri(
          amount: loaded.requestedAmount,
          token: loaded.tokenCurrency,
        );
        final isLightningNow = newUri is LightningPaymentRequest;

        CryptoCurrency nextCrypto = loaded.cryptoCurrency;
        if (isLightningNow && !loaded.isLightning) {
          nextCrypto = CryptoCurrency.btcln;
        } else if (!isLightningNow && loaded.cryptoCurrency == CryptoCurrency.btcln) {
          nextCrypto = loaded.walletCurrency;
        }

        if (isLightningNow && loaded.requestedAmount != null) {
          invoiceAmountToFetch = loaded.requestedAmount;
        }

        emit(
          loaded.copyWith(
            addressType: event.option,
            addressEntry: _currentAddressEntry(),
            paymentUri: newUri,
            cryptoCurrency: nextCrypto,
            isSilentPayments: addressService.isSilentPayments,
            isLightning: isLightningNow,
            isZCashTransparent: addressService.isZCashTransparent,
            isChangingAddressType: false,
            isFetchingInvoice: invoiceAmountToFetch != null,
          ),
        );
      } catch (e) {
        printV("ReceiveBloc address type refresh failed: $e");
        _failAddressTypeChange(emit, initial.walletId);
        return;
      }

      if (invoiceAmountToFetch != null) {
        await _fetchLightningInvoice(
          emit,
          walletId: initial.walletId,
          amount: invoiceAmountToFetch,
        );
      }
    }
  }

  void _failAddressTypeChange(Emitter<ReceiveState> emit, String walletId) {
    if (isClosed) {
      return;
    }
    if (state case final ReceiveLoaded loaded when loaded.walletId == walletId) {
      emit(loaded.copyWith(isChangingAddressType: false));
      emitPresentation(const ReceiveAddressTypeChangeFailed());
    }
  }

  Future<void> _onAddressRotated(AddressRotated event, Emitter<ReceiveState> emit) async {
    final initial = state;
    if (initial is! ReceiveLoaded) {
      return;
    }

    emit(initial.copyWith(isRotatingAddress: true));

    try {
      await addressService.rotateAddress();
    } catch (e) {
      printV("ReceiveBloc rotate failed: $e");
      if (isClosed) {
        return;
      }
      if (state case final ReceiveLoaded loaded when loaded.walletId == initial.walletId) {
        emit(loaded.copyWith(isRotatingAddress: false));
        emitPresentation(const ReceiveAddressRotationFailed());
      }
      return;
    }

    if (isClosed) {
      return;
    }
    if (state case final ReceiveLoaded loaded when loaded.walletId == initial.walletId) {
      emit(
        loaded.copyWith(
          addressEntry: _currentAddressEntry(),
          paymentUri: addressService.buildPaymentUri(
            amount: loaded.requestedAmount,
            token: loaded.tokenCurrency,
          ),
          isRotatingAddress: false,
        ),
      );
    }
  }

  Future<void> _onLabelSubmitted(LabelSubmitted event, Emitter<ReceiveState> emit) async {
    final initial = state;
    if (initial is! ReceiveLoaded) {
      return;
    }

    try {
      await addressService.setLabel(initial.addressEntry, event.label);
    } catch (e) {
      printV("ReceiveBloc setLabel failed: $e");
      if (!isClosed) {
        emitPresentation(const ReceiveLabelUpdateFailed());
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
    if (initial is! ReceiveLoaded || initial.isInfoboxDismissed) {
      return;
    }

    final wallet = addressService.wallet;
    if (wallet.id != initial.walletId) {
      return;
    }

    final walletInfo = wallet.walletInfo;
    walletInfo.receiveInfoboxDismissed = true;
    try {
      await walletInfo.save();
    } catch (e) {
      printV("ReceiveBloc failed to save receiveInfoboxDismissed: $e");
    }
    if (isClosed) {
      return;
    }
    if (state case final ReceiveLoaded loaded when loaded.walletId == initial.walletId) {
      emit(loaded.copyWith(isInfoboxDismissed: true));
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
          amount: loaded.requestedAmount,
          token: loaded.tokenCurrency,
        ),
      ),
    );
  }

  Future<void> _onWalletChanged(_WalletChanged event, Emitter<ReceiveState> emit) async {
    emit(const ReceiveLoading());
    try {
      await addressService.applyOpenDefaults(lightningMode: false);
      addressService.applyAutoGenerateOverride();

      if (isClosed) {
        return;
      }
      emit(_buildLoaded(initialToken: null));
    } catch (e) {
      printV("ReceiveBloc _onWalletChanged failed: $e");
      if (!isClosed) {
        emit(const ReceiveFailure());
      }
    }
  }

  Future<void> _onFiatRateChanged(_FiatRateChanged event, Emitter<ReceiveState> emit) async {
    final loaded = state;
    if (loaded is! ReceiveLoaded) {
      return;
    }
    if (loaded.fiatCurrency != null && loaded.fiatEquivalent != null) {
      if (loaded.isLightning) {
        return;
      }
      final newCrypto = fiatRateService.convert(loaded.fiatEquivalent!, loaded.cryptoCurrency);
      final uri = addressService.buildPaymentUri(
        amount: newCrypto,
        token: loaded.tokenCurrency,
      );
      emit(loaded.copyWith(requestedAmount: () => newCrypto, paymentUri: uri));
      return;
    }

    if (loaded.requestedAmount == null) {
      return;
    }
    final newFiat = fiatRateService.convert(loaded.requestedAmount!, event.fiat);
    emit(loaded.copyWith(fiatEquivalent: () => newFiat));
  }

  Future<void> _onPayjoinEndpointChanged(
    _PayjoinEndpointChanged event,
    Emitter<ReceiveState> emit,
  ) async {
    final loaded = state;
    if (loaded is! ReceiveLoaded) {
      return;
    }

    if (loaded.isLightning) {
      return;
    }

    emit(
      loaded.copyWith(
        paymentUri: addressService.buildPaymentUri(
          amount: loaded.requestedAmount,
          token: loaded.tokenCurrency,
        ),
      ),
    );
  }

  Future<void> _fetchLightningInvoice(
    Emitter<ReceiveState> emit, {
    required String walletId,
    Money? amount,
  }) async {
    bool matchesRequest(ReceiveLoaded loaded) =>
        loaded.walletId == walletId && loaded.isLightning && loaded.requestedAmount == amount;

    try {
      final uri = await addressService.fetchPaymentRequestUri(amount: amount, token: null);
      if (isClosed) {
        return;
      }
      if (state case final ReceiveLoaded loaded when matchesRequest(loaded)) {
        emit(loaded.copyWith(paymentUri: uri, isFetchingInvoice: false));
      }
    } catch (e) {
      printV("ReceiveBloc lightning invoice fetch failed: $e");
      if (isClosed) {
        return;
      }
      if (state case final ReceiveLoaded loaded
          when loaded.walletId == walletId && loaded.isLightning) {
        PaymentURI? plainUri;
        try {
          plainUri = addressService.buildPaymentUri();
        } catch (e) {
          printV("ReceiveBloc plain lightning uri rebuild failed: $e");
        }

        emit(
          loaded.copyWith(
            isFetchingInvoice: false,
            requestedAmount: () => null,
            fiatEquivalent: () => null,
            paymentUri: plainUri,
          ),
        );
        emitPresentation(const ReceiveInvoiceFetchFailed());
      }
    }
  }

  ReceiveLoaded _buildLoaded({CryptoCurrency? initialToken}) {
    final wallet = addressService.wallet;
    CryptoCurrency crypto = initialToken ?? wallet.currency;
    final uri = addressService.buildPaymentUri(token: crypto == wallet.currency ? null : crypto);
    if (crypto == CryptoCurrency.btcln && uri is! LightningPaymentRequest) {
      crypto = wallet.currency;
    }

    return ReceiveLoaded(
      addressEntry: _currentAddressEntry(),
      addressType: addressService.selectedAddressType,
      addressTypeOptions: addressService.addressTypeOptions,
      cryptoCurrency: crypto,
      fiatCurrency: null,
      receivableTokens: addressService.receivableTokens,
      requestedAmount: null,
      fiatEquivalent: null,
      isInfoboxDismissed: wallet.walletInfo.receiveInfoboxDismissed,
      isFetchingInvoice: false,
      isRotatingAddress: false,
      paymentUri: uri,
      isSilentPayments: addressService.isSilentPayments,
      isLightning: uri is LightningPaymentRequest,
      isZCashTransparent: addressService.isZCashTransparent,
      walletId: wallet.id,
      walletType: wallet.type,
      walletCurrency: wallet.currency,
      hasTokens: addressService.hasTokens,
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
}
