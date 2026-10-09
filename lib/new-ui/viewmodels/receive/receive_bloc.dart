import "dart:async";

import "package:bloc/bloc.dart";
import "package:bloc_concurrency/bloc_concurrency.dart";
import "package:bloc_presentation/bloc_presentation.dart";
import "package:cake_wallet/core/address_service.dart";
import "package:cake_wallet/core/fiat_rate_service.dart";
import "package:cake_wallet/entities/auto_generate_subaddress_status.dart";
import "package:cake_wallet/entities/fiat_currency.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/reactions/wallet_utils.dart" as wallet_utils;
import "package:cake_wallet/utils/qr_util.dart";
import "package:cw_core/address_entry.dart";
import "package:cw_core/address_generation_wallet.dart";
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
    required this.wallet,
    required this.addressService,
    required this.fiatRateService,
    CryptoCurrency? initialToken,
    ReceivePageOption? initialAddressType,
  })  : _initialToken = initialToken,
        _initialAddressType = initialAddressType,
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
    on<_FiatRateChanged>(_onFiatRateChanged, transformer: sequential());
    on<_PayjoinEndpointChanged>(_onPayjoinEndpointChanged, transformer: sequential());

    _rateSub = fiatRateService.rateChanges.listen((fiat) {
      if (!isClosed) {
        add(_FiatRateChanged(fiat));
      }
    });
    _payjoinSub = addressService.payjoinEndpointChanges(wallet).listen((_) {
      if (!isClosed) {
        add(const _PayjoinEndpointChanged());
      }
    });
  }

  final WalletBase wallet;
  final AddressService addressService;
  final FiatRateService fiatRateService;
  final CryptoCurrency? _initialToken;
  final ReceivePageOption? _initialAddressType;

  late final StreamSubscription<FiatCurrency> _rateSub;
  late final StreamSubscription<void> _payjoinSub;

  AutoGenerateSubaddressStatus get autoGenerateSubaddressStatus =>
      addressService.autoGenerateSubaddressStatus;

  List<ReceivePageOption> get addressTypeOptions => wallet.addressTypeOptions;

  List<CryptoCurrency> get receivableTokens =>
      wallet.balance.keys.whereType<CryptoCurrency>().toList();

  bool get hasTokens => wallet_utils.hasTokens(wallet.type);

  bool get canGenerateAddresses => wallet is AddressGenerationWallet;

  WalletType get walletType => wallet.type;

  CryptoCurrency get walletCurrency => wallet.currency;

  CryptoCurrency? selectedToken(ReceiveLoaded state) =>
      state.cryptoCurrency == walletCurrency ? null : state.cryptoCurrency;

  String qrEmbeddedIconOf(ReceiveLoaded state) {
    final token = selectedToken(state);
    if (token != null && token != CryptoCurrency.btcln) {
      return token.iconPath ?? getQrImage(walletType);
    }
    if (state.isLightning) {
      return "assets/images/btc_chain_qr_lightning.svg";
    }
    return getQrImage(walletType);
  }

  @override
  Future<void> close() async {
    await _rateSub.cancel();
    await _payjoinSub.cancel();
    return super.close();
  }

  void _init(Init event, Emitter<ReceiveState> emit) {
    emit(const ReceiveLoading());

    try {
      if (wallet.isEnabledAutoGenerateSubaddress) {
        final latestAddress = wallet.walletAddresses.latestAddress;
        if (latestAddress.isNotEmpty) {
          wallet.walletAddresses.address = latestAddress;
        }
      }

      final requestedType = _initialAddressType;
      final isRequestedTypeOffered =
          requestedType == null || addressTypeOptions.contains(requestedType);
      final type = isRequestedTypeOffered && requestedType != null
          ? requestedType
          : wallet.walletAddresses.defaultAddressType;
      final groups = wallet.walletAddresses.addressListFor(type);
      final uri = wallet.walletAddresses.paymentUriFor(type, "", token: _initialToken);
      CryptoCurrency crypto = _initialToken ?? wallet.currency;
      if (uri is LightningPaymentRequest) {
        crypto = CryptoCurrency.btcln;
      } else if (crypto == CryptoCurrency.btcln) {
        crypto = wallet.currency;
      }

      emit(
        ReceiveLoaded(
          addressType: type,
          addressEntry: _currentAddressEntry(type, groups),
          hasAddressList: groups.isNotEmpty,
          hasAddressRotation: _hasAddressRotation(type, groups),
          cryptoCurrency: crypto,
          fiatCurrency: null,
          requestedAmount: null,
          fiatEquivalent: null,
          isInfoboxDismissed: wallet.walletInfo.receiveInfoboxDismissed,
          isFetchingInvoice: false,
          isRotatingAddress: false,
          paymentUri: uri,
        ),
      );

      if (!isRequestedTypeOffered) {
        emitPresentation(ReceiveAddressTypeUnavailable(requested: requestedType, shown: type));
      }
    } catch (e) {
      printV("ReceiveBloc _init failed: $e");
      emit(const ReceiveFailure());
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
      requestedAmount = fiatRateService.convert(amount, initial.cryptoCurrency);
      if (requestedAmount == null) {
        if (state case final ReceiveLoaded loaded) {
          emit(
            loaded.copyWith(
              requestedAmount: () => null,
              fiatEquivalent: () => null,
              paymentUri: loaded.isLightning ? null : _paymentUri(loaded, amount: null),
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

      await _fetchLightningInvoice(emit, amount: requestedAmount);
    } else if (state case final ReceiveLoaded loaded) {
      emit(
        loaded.copyWith(
          requestedAmount: () => requestedAmount,
          fiatEquivalent: () => fiatEquivalent,
          paymentUri: _paymentUri(loaded, amount: requestedAmount),
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
    if (state case final ReceiveLoaded loaded when loaded.requestedAmount != null) {
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

    final crypto = event.token ?? walletCurrency;
    if (crypto != walletCurrency && !receivableTokens.contains(crypto)) {
      return;
    }

    final next = loaded.copyWith(
      cryptoCurrency: crypto,
      requestedAmount: () => null,
      fiatEquivalent: () => null,
    );
    emit(next.copyWith(paymentUri: _paymentUri(next, amount: null)));

    if (loaded.fiatCurrency != null) {
      await fiatRateService.ensureRateFor(crypto, loaded.fiatCurrency!);
    }
  }

  Future<void> _onAddressTypeSelected(
    AddressTypeSelected event,
    Emitter<ReceiveState> emit,
  ) async {
    final loaded = state;
    if (loaded is! ReceiveLoaded) {
      return;
    }

    final type = event.option;
    Money? invoiceAmountToFetch;
    try {
      final groups = wallet.walletAddresses.addressListFor(type);
      final newUri = wallet.walletAddresses.paymentUriFor(
        type,
        _rawAmount(loaded.requestedAmount),
        token: selectedToken(loaded),
      );
      final isLightningNow = newUri is LightningPaymentRequest;

      CryptoCurrency nextCrypto = loaded.cryptoCurrency;
      if (isLightningNow && !loaded.isLightning) {
        nextCrypto = CryptoCurrency.btcln;
      } else if (!isLightningNow && loaded.cryptoCurrency == CryptoCurrency.btcln) {
        nextCrypto = walletCurrency;
      }

      final requestedAmount = loaded.requestedAmount;
      final amountInNextCrypto = requestedAmount != null && nextCrypto != loaded.cryptoCurrency
          ? Money(requestedAmount.amount, nextCrypto)
          : requestedAmount;

      if (isLightningNow && amountInNextCrypto != null) {
        invoiceAmountToFetch = amountInNextCrypto;
      }

      emit(
        loaded.copyWith(
          addressType: type,
          addressEntry: _currentAddressEntry(type, groups),
          hasAddressList: groups.isNotEmpty,
          hasAddressRotation: _hasAddressRotation(type, groups),
          paymentUri: newUri,
          cryptoCurrency: nextCrypto,
          requestedAmount: () => amountInNextCrypto,
          isFetchingInvoice: invoiceAmountToFetch != null,
        ),
      );
    } catch (e) {
      printV("ReceiveBloc address type change failed: $e");
      emitPresentation(const ReceiveAddressTypeChangeFailed());
      return;
    }

    if (invoiceAmountToFetch != null) {
      await _fetchLightningInvoice(emit, amount: invoiceAmountToFetch);
    }
  }

  Future<void> _onAddressRotated(AddressRotated event, Emitter<ReceiveState> emit) async {
    final initial = state;
    if (initial is! ReceiveLoaded) {
      return;
    }

    emit(initial.copyWith(isRotatingAddress: true));

    try {
      await (wallet as AddressGenerationWallet).generateNewAddress(
        initial.addressType,
        setAsActive: true,
      );
    } catch (e) {
      printV("ReceiveBloc rotate failed: $e");
      if (isClosed) {
        return;
      }
      if (state case final ReceiveLoaded loaded) {
        emit(loaded.copyWith(isRotatingAddress: false));
        emitPresentation(const ReceiveAddressRotationFailed());
      }
      return;
    }

    if (isClosed) {
      return;
    }
    if (state case final ReceiveLoaded loaded) {
      emit(_withCurrentAddress(loaded).copyWith(isRotatingAddress: false));
    }
  }

  Future<void> _onLabelSubmitted(LabelSubmitted event, Emitter<ReceiveState> emit) async {
    final initial = state;
    if (initial is! ReceiveLoaded) {
      return;
    }

    try {
      await (wallet as AddressGenerationWallet).setAddressLabel(initial.addressEntry, event.label);
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
    if (state case final ReceiveLoaded loaded) {
      emit(_withCurrentAddress(loaded));
    }
  }

  Future<void> _onInfoboxDismissed(InfoboxDismissed event, Emitter<ReceiveState> emit) async {
    final initial = state;
    if (initial is! ReceiveLoaded || initial.isInfoboxDismissed) {
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
    if (state case final ReceiveLoaded loaded) {
      emit(loaded.copyWith(isInfoboxDismissed: true));
    }
  }

  void _onAddressesPageClosed(AddressesPageClosed event, Emitter<ReceiveState> emit) {
    if (state case final ReceiveLoaded loaded) {
      emit(_withCurrentAddress(loaded));
    }
  }

  void _onFiatRateChanged(_FiatRateChanged event, Emitter<ReceiveState> emit) {
    final loaded = state;
    if (loaded is! ReceiveLoaded) {
      return;
    }
    if (loaded.fiatCurrency != null && loaded.fiatEquivalent != null) {
      if (loaded.isLightning) {
        return;
      }
      final newCrypto = fiatRateService.convert(loaded.fiatEquivalent!, loaded.cryptoCurrency);
      emit(
        loaded.copyWith(
          requestedAmount: () => newCrypto,
          paymentUri: _paymentUri(loaded, amount: newCrypto),
        ),
      );
      return;
    }

    if (loaded.requestedAmount == null) {
      return;
    }
    final newFiat = fiatRateService.convert(loaded.requestedAmount!, event.fiat);
    emit(loaded.copyWith(fiatEquivalent: () => newFiat));
  }

  void _onPayjoinEndpointChanged(_PayjoinEndpointChanged event, Emitter<ReceiveState> emit) {
    if (state case final ReceiveLoaded loaded when !loaded.isLightning) {
      emit(loaded.copyWith(paymentUri: _paymentUri(loaded, amount: loaded.requestedAmount)));
    }
  }

  Future<void> _fetchLightningInvoice(Emitter<ReceiveState> emit, {Money? amount}) async {
    final initial = state;
    if (initial is! ReceiveLoaded) {
      return;
    }

    bool matchesRequest(ReceiveLoaded loaded) =>
        loaded.isLightning && loaded.requestedAmount == amount;

    try {
      final uri = await wallet.walletAddresses.paymentRequestUriFor(
        initial.addressType,
        _rawAmount(amount),
      );
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
      if (state case final ReceiveLoaded loaded when loaded.isLightning) {
        PaymentURI? plainUri;
        try {
          plainUri = wallet.walletAddresses.paymentUriFor(loaded.addressType, "");
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

  PaymentURI _paymentUri(ReceiveLoaded loaded, {required Money? amount}) =>
      wallet.walletAddresses.paymentUriFor(
        loaded.addressType,
        _rawAmount(amount),
        token: selectedToken(loaded),
      );

  String _rawAmount(Money? amount) => amount?.toStringWithPrecision() ?? "";

  ReceiveLoaded _withCurrentAddress(ReceiveLoaded loaded) => loaded.copyWith(
        addressEntry: _currentAddressEntry(
          loaded.addressType,
          wallet.walletAddresses.addressListFor(loaded.addressType),
        ),
        paymentUri: _paymentUri(loaded, amount: loaded.requestedAmount),
      );

  bool _hasAddressRotation(ReceivePageOption type, List<AddressGroup> groups) =>
      groups.isNotEmpty && canGenerateAddresses && type.canRotateAddress;

  AddressEntry _currentAddressEntry(ReceivePageOption type, List<AddressGroup> groups) {
    final current = wallet.walletAddresses.addressFor(type);
    return groups.expand((group) => group.entries).firstWhere(
          (entry) => entry.address == current,
          orElse: () => AddressEntry(address: current),
        );
  }
}
