part of "receive_bloc.dart";

sealed class ReceiveState extends Equatable {
  const ReceiveState();

  @override
  List<Object?> get props => const [];
}

final class ReceiveLoading extends ReceiveState {
  const ReceiveLoading();
}

final class ReceiveLoaded extends ReceiveState {
  const ReceiveLoaded({
    required this.addressEntry,
    required this.addressType,
    required this.addressTypeOptions,
    required this.inputCurrency,
    required this.tokenCurrency,
    required this.receivableTokens,
    required this.requestedAmount,
    required this.fiatEquivalent,
    required this.infoboxDismissed,
    required this.payjoinEndpoint,
    required this.fetchingInvoice,
    required this.isRotatingAddress,
    required this.paymentUri,
    required this.isSilentPayments,
    required this.isLightning,
    required this.autoGenerateSubaddressStatus,
    required this.isZCashTransparent,
    required this.inputUsesSats,
    required this.receiveUsesSats,
    required this.walletId,
    required this.walletType,
    required this.walletCurrency,
    required this.hasTokensList,
    this.isChangingAddressType = false,
    this.failureCode,
  });

  final AddressEntry addressEntry;
  final ReceivePageOption? addressType;
  final List<ReceivePageOption> addressTypeOptions;

  final Currency inputCurrency;
  final CryptoCurrency? tokenCurrency;
  final List<CryptoCurrency> receivableTokens;

  final Money? requestedAmount;
  final Money? fiatEquivalent;

  final bool infoboxDismissed;
  final String? payjoinEndpoint;
  final bool fetchingInvoice;
  final bool isRotatingAddress;
  final bool isChangingAddressType;

  final PaymentURI paymentUri;

  final bool isSilentPayments;
  final bool isLightning;
  final AutoGenerateSubaddressStatus autoGenerateSubaddressStatus;
  final bool isZCashTransparent;
  final bool inputUsesSats;
  final bool receiveUsesSats;

  final String walletId;
  final WalletType walletType;
  final CryptoCurrency walletCurrency;
  final bool hasTokensList;
  final ReceiveFailureCode? failureCode;

  bool get hasPayjoin =>
      walletType == WalletType.bitcoin &&
      !isLightning &&
      !isSilentPayments &&
      paymentUri.toString().contains("pj=");

  bool get hasAddressList {
    if (isLightning) {
      return false;
    }
    if (walletType == WalletType.zcash && !isZCashTransparent) {
      return false;
    }
    return const {
      WalletType.monero,
      WalletType.wownero,
      WalletType.bitcoinCash,
      WalletType.bitcoin,
      WalletType.litecoin,
      WalletType.decred,
      WalletType.dogecoin,
      WalletType.zcash,
    }.contains(walletType);
  }

  bool get hasAddressRotation => hasAddressList && walletType != WalletType.zcash;

  String get requestedAmountDisplay {
    final amount = requestedAmount;
    if (amount == null) {
      return "";
    }
    return amount.toStringWithPrecision(useBaseUnit: receiveUsesSats);
  }

  String get receiveCryptoSymbol => _cryptoSymbol(tokenCurrency ?? walletCurrency, receiveUsesSats);

  String get inputCurrencySymbol {
    final c = inputCurrency;
    if (c is CryptoCurrency) {
      return _cryptoSymbol(c, inputUsesSats);
    }
    return c.name.toUpperCase();
  }

  String get modalInitialAmount {
    if (inputCurrency is FiatCurrency) {
      return fiatEquivalent?.toStringWithPrecision() ?? "";
    }
    return requestedAmountDisplay;
  }

  static String _cryptoSymbol(CryptoCurrency c, bool useSats) {
    if (useSats) {
      return "sats";
    }
    final title = c.title;
    return title.length <= 8 ? title : title.substring(0, 8);
  }

  ReceiveLoaded copyWith({
    AddressEntry? addressEntry,
    ReceivePageOption? addressType,
    List<ReceivePageOption>? addressTypeOptions,
    Currency? inputCurrency,
    CryptoCurrency? tokenCurrency,
    bool clearTokenCurrency = false,
    List<CryptoCurrency>? receivableTokens,
    Money? requestedAmount,
    bool clearRequestedAmount = false,
    Money? fiatEquivalent,
    bool clearFiatEquivalent = false,
    bool? infoboxDismissed,
    String? payjoinEndpoint,
    bool clearPayjoinEndpoint = false,
    bool? fetchingInvoice,
    bool? isRotatingAddress,
    bool? isChangingAddressType,
    PaymentURI? paymentUri,
    bool? isSilentPayments,
    bool? isLightning,
    AutoGenerateSubaddressStatus? autoGenerateSubaddressStatus,
    bool? isZCashTransparent,
    bool? inputUsesSats,
    bool? receiveUsesSats,
    String? walletId,
    WalletType? walletType,
    CryptoCurrency? walletCurrency,
    bool? hasTokensList,
    ReceiveFailureCode? failureCode,
    bool clearFailureCode = false,
  }) =>
      ReceiveLoaded(
        addressEntry: addressEntry ?? this.addressEntry,
        addressType: addressType ?? this.addressType,
        addressTypeOptions: addressTypeOptions ?? this.addressTypeOptions,
        inputCurrency: inputCurrency ?? this.inputCurrency,
        tokenCurrency: clearTokenCurrency ? null : (tokenCurrency ?? this.tokenCurrency),
        receivableTokens: receivableTokens ?? this.receivableTokens,
        requestedAmount: clearRequestedAmount ? null : (requestedAmount ?? this.requestedAmount),
        fiatEquivalent: clearFiatEquivalent ? null : (fiatEquivalent ?? this.fiatEquivalent),
        infoboxDismissed: infoboxDismissed ?? this.infoboxDismissed,
        payjoinEndpoint: clearPayjoinEndpoint ? null : (payjoinEndpoint ?? this.payjoinEndpoint),
        fetchingInvoice: fetchingInvoice ?? this.fetchingInvoice,
        isRotatingAddress: isRotatingAddress ?? this.isRotatingAddress,
        isChangingAddressType: isChangingAddressType ?? this.isChangingAddressType,
        paymentUri: paymentUri ?? this.paymentUri,
        isSilentPayments: isSilentPayments ?? this.isSilentPayments,
        isLightning: isLightning ?? this.isLightning,
        autoGenerateSubaddressStatus:
            autoGenerateSubaddressStatus ?? this.autoGenerateSubaddressStatus,
        isZCashTransparent: isZCashTransparent ?? this.isZCashTransparent,
        inputUsesSats: inputUsesSats ?? this.inputUsesSats,
        receiveUsesSats: receiveUsesSats ?? this.receiveUsesSats,
        walletId: walletId ?? this.walletId,
        walletType: walletType ?? this.walletType,
        walletCurrency: walletCurrency ?? this.walletCurrency,
        hasTokensList: hasTokensList ?? this.hasTokensList,
        failureCode: clearFailureCode ? null : (failureCode ?? this.failureCode),
      );

  @override
  List<Object?> get props => [
        addressEntry,
        addressType,
        addressTypeOptions,
        inputCurrency,
        tokenCurrency,
        receivableTokens,
        requestedAmount,
        fiatEquivalent,
        infoboxDismissed,
        payjoinEndpoint,
        fetchingInvoice,
        isRotatingAddress,
        isChangingAddressType,
        paymentUri.toString(),
        isSilentPayments,
        isLightning,
        autoGenerateSubaddressStatus,
        isZCashTransparent,
        inputUsesSats,
        receiveUsesSats,
        walletId,
        walletType,
        walletCurrency,
        hasTokensList,
        failureCode,
      ];
}

final class ReceiveFailure extends ReceiveState {
  const ReceiveFailure(this.code);

  final ReceiveFailureCode code;

  @override
  List<Object?> get props => [code];
}

enum ReceiveFailureCode {
  walletNotReady,
  addressListUnavailable,
  invoiceFetchFailed,
}
