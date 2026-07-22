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
    required this.hasAccounts,
    required this.accountLabel,
    required this.isSilentPayments,
    required this.isLightning,
    required this.isBitcoinViewOnly,
    required this.isAutoGenerateSubaddressEnabled,
    required this.autoGenerateSubaddressStatus,
    required this.isZCashTransparent,
    required this.useSatoshi,
    required this.walletType,
    required this.walletCurrency,
    required this.hasTokensList,
    this.isChangingAddressType = false,
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

  final bool hasAccounts;
  final String? accountLabel;
  final bool isSilentPayments;
  final bool isLightning;
  final bool isBitcoinViewOnly;
  final bool isAutoGenerateSubaddressEnabled;
  final AutoGenerateSubaddressStatus autoGenerateSubaddressStatus;
  final bool isZCashTransparent;
  final bool useSatoshi;

  final WalletType walletType;
  final CryptoCurrency walletCurrency;
  final bool hasTokensList;

  bool get hasPayjoin =>
      payjoinEndpoint != null && payjoinEndpoint!.isNotEmpty && !isSilentPayments && !isLightning;

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
    bool? hasAccounts,
    String? accountLabel,
    bool clearAccountLabel = false,
    bool? isSilentPayments,
    bool? isLightning,
    bool? isBitcoinViewOnly,
    bool? isAutoGenerateSubaddressEnabled,
    AutoGenerateSubaddressStatus? autoGenerateSubaddressStatus,
    bool? isZCashTransparent,
    bool? useSatoshi,
    WalletType? walletType,
    CryptoCurrency? walletCurrency,
    bool? hasTokensList,
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
        hasAccounts: hasAccounts ?? this.hasAccounts,
        accountLabel: clearAccountLabel ? null : (accountLabel ?? this.accountLabel),
        isSilentPayments: isSilentPayments ?? this.isSilentPayments,
        isLightning: isLightning ?? this.isLightning,
        isBitcoinViewOnly: isBitcoinViewOnly ?? this.isBitcoinViewOnly,
        isAutoGenerateSubaddressEnabled:
            isAutoGenerateSubaddressEnabled ?? this.isAutoGenerateSubaddressEnabled,
        autoGenerateSubaddressStatus:
            autoGenerateSubaddressStatus ?? this.autoGenerateSubaddressStatus,
        isZCashTransparent: isZCashTransparent ?? this.isZCashTransparent,
        useSatoshi: useSatoshi ?? this.useSatoshi,
        walletType: walletType ?? this.walletType,
        walletCurrency: walletCurrency ?? this.walletCurrency,
        hasTokensList: hasTokensList ?? this.hasTokensList,
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
        hasAccounts,
        accountLabel,
        isSilentPayments,
        isLightning,
        isBitcoinViewOnly,
        isAutoGenerateSubaddressEnabled,
        autoGenerateSubaddressStatus,
        isZCashTransparent,
        useSatoshi,
        walletType,
        walletCurrency,
        hasTokensList,
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
