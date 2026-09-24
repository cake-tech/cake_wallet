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
    required this.cryptoCurrency,
    required this.fiatCurrency,
    required this.receivableTokens,
    required this.requestedAmount,
    required this.fiatEquivalent,
    required this.isInfoboxDismissed,
    required this.isFetchingInvoice,
    required this.isRotatingAddress,
    required this.paymentUri,
    required this.isSilentPayments,
    required this.isLightning,
    required this.isZCashTransparent,
    required this.walletId,
    required this.walletType,
    required this.walletCurrency,
    required this.hasTokens,
    this.isChangingAddressType = false,
  });

  final AddressEntry addressEntry;
  final ReceivePageOption addressType;
  final List<ReceivePageOption> addressTypeOptions;

  final CryptoCurrency cryptoCurrency;
  final FiatCurrency? fiatCurrency;
  final List<CryptoCurrency> receivableTokens;

  final Money? requestedAmount;
  final Money? fiatEquivalent;

  final bool isInfoboxDismissed;
  final bool isFetchingInvoice;
  final bool isRotatingAddress;
  final bool isChangingAddressType;

  final PaymentURI paymentUri;

  final bool isSilentPayments;
  final bool isLightning;
  final bool isZCashTransparent;

  final String walletId;
  final WalletType walletType;
  final CryptoCurrency walletCurrency;
  final bool hasTokens;

  Currency get inputCurrency => fiatCurrency ?? cryptoCurrency;

  CryptoCurrency? get tokenCurrency => cryptoCurrency == walletCurrency ? null : cryptoCurrency;

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
      WalletType.bitcoinCash,
      WalletType.bitcoin,
      WalletType.litecoin,
      WalletType.decred,
      WalletType.dogecoin,
      WalletType.zcash,
    }.contains(walletType);
  }

  bool get hasAddressRotation =>
      hasAddressList && walletType != WalletType.zcash && addressType.canRotateAddress;

  Money? get amountInInputCurrency => fiatCurrency != null ? fiatEquivalent : requestedAmount;

  String get qrEmbeddedIcon {
    final token = tokenCurrency;
    if (token != null && token != CryptoCurrency.btcln) {
      return token.iconPath ?? getQrImage(walletType);
    }
    if (isLightning) {
      return "assets/images/btc_chain_qr_lightning.svg";
    }
    return getQrImage(walletType);
  }

  ReceiveLoaded copyWith({
    AddressEntry? addressEntry,
    ReceivePageOption? addressType,
    CryptoCurrency? cryptoCurrency,
    ValueGetter<FiatCurrency?>? fiatCurrency,
    ValueGetter<Money?>? requestedAmount,
    ValueGetter<Money?>? fiatEquivalent,
    bool? isInfoboxDismissed,
    bool? isFetchingInvoice,
    bool? isRotatingAddress,
    bool? isChangingAddressType,
    PaymentURI? paymentUri,
    bool? isSilentPayments,
    bool? isLightning,
    bool? isZCashTransparent,
  }) =>
      ReceiveLoaded(
        addressEntry: addressEntry ?? this.addressEntry,
        addressType: addressType ?? this.addressType,
        addressTypeOptions: addressTypeOptions,
        cryptoCurrency: cryptoCurrency ?? this.cryptoCurrency,
        fiatCurrency: fiatCurrency != null ? fiatCurrency() : this.fiatCurrency,
        receivableTokens: receivableTokens,
        requestedAmount: requestedAmount != null ? requestedAmount() : this.requestedAmount,
        fiatEquivalent: fiatEquivalent != null ? fiatEquivalent() : this.fiatEquivalent,
        isInfoboxDismissed: isInfoboxDismissed ?? this.isInfoboxDismissed,
        isFetchingInvoice: isFetchingInvoice ?? this.isFetchingInvoice,
        isRotatingAddress: isRotatingAddress ?? this.isRotatingAddress,
        isChangingAddressType: isChangingAddressType ?? this.isChangingAddressType,
        paymentUri: paymentUri ?? this.paymentUri,
        isSilentPayments: isSilentPayments ?? this.isSilentPayments,
        isLightning: isLightning ?? this.isLightning,
        isZCashTransparent: isZCashTransparent ?? this.isZCashTransparent,
        walletId: walletId,
        walletType: walletType,
        walletCurrency: walletCurrency,
        hasTokens: hasTokens,
      );

  @override
  List<Object?> get props => [
        addressEntry,
        addressType,
        addressTypeOptions,
        cryptoCurrency,
        fiatCurrency,
        receivableTokens,
        requestedAmount,
        fiatEquivalent,
        isInfoboxDismissed,
        isFetchingInvoice,
        isRotatingAddress,
        isChangingAddressType,
        paymentUri.toString(),
        isSilentPayments,
        isLightning,
        isZCashTransparent,
        walletId,
        walletType,
        walletCurrency,
        hasTokens,
      ];
}

final class ReceiveFailure extends ReceiveState {
  const ReceiveFailure();

  String get message => S.current.receive_error_address_list;
}
