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
    required this.addressType,
    required this.addressEntry,
    required this.hasAddressList,
    required this.hasAddressRotation,
    required this.cryptoCurrency,
    required this.fiatCurrency,
    required this.requestedAmount,
    required this.fiatEquivalent,
    required this.isInfoboxDismissed,
    required this.isFetchingInvoice,
    required this.isRotatingAddress,
    required this.paymentUri,
  });

  final ReceivePageOption addressType;
  final AddressEntry addressEntry;
  final bool hasAddressList;
  final bool hasAddressRotation;

  final CryptoCurrency cryptoCurrency;
  final FiatCurrency? fiatCurrency;

  final Money? requestedAmount;
  final Money? fiatEquivalent;

  final bool isInfoboxDismissed;
  final bool isFetchingInvoice;
  final bool isRotatingAddress;

  final PaymentURI paymentUri;

  Currency get inputCurrency => fiatCurrency ?? cryptoCurrency;

  bool get isLightning => paymentUri is LightningPaymentRequest;

  bool get hasPayjoin => paymentUri.toString().contains("pj=");

  Money? get amountInInputCurrency => fiatCurrency != null ? fiatEquivalent : requestedAmount;

  ReceiveLoaded copyWith({
    ReceivePageOption? addressType,
    AddressEntry? addressEntry,
    bool? hasAddressList,
    bool? hasAddressRotation,
    CryptoCurrency? cryptoCurrency,
    ValueGetter<FiatCurrency?>? fiatCurrency,
    ValueGetter<Money?>? requestedAmount,
    ValueGetter<Money?>? fiatEquivalent,
    bool? isInfoboxDismissed,
    bool? isFetchingInvoice,
    bool? isRotatingAddress,
    PaymentURI? paymentUri,
  }) =>
      ReceiveLoaded(
        addressType: addressType ?? this.addressType,
        addressEntry: addressEntry ?? this.addressEntry,
        hasAddressList: hasAddressList ?? this.hasAddressList,
        hasAddressRotation: hasAddressRotation ?? this.hasAddressRotation,
        cryptoCurrency: cryptoCurrency ?? this.cryptoCurrency,
        fiatCurrency: fiatCurrency != null ? fiatCurrency() : this.fiatCurrency,
        requestedAmount: requestedAmount != null ? requestedAmount() : this.requestedAmount,
        fiatEquivalent: fiatEquivalent != null ? fiatEquivalent() : this.fiatEquivalent,
        isInfoboxDismissed: isInfoboxDismissed ?? this.isInfoboxDismissed,
        isFetchingInvoice: isFetchingInvoice ?? this.isFetchingInvoice,
        isRotatingAddress: isRotatingAddress ?? this.isRotatingAddress,
        paymentUri: paymentUri ?? this.paymentUri,
      );

  @override
  List<Object?> get props => [
        addressType,
        addressEntry.address,
        addressEntry.label,
        hasAddressList,
        hasAddressRotation,
        cryptoCurrency,
        fiatCurrency,
        requestedAmount,
        fiatEquivalent,
        isInfoboxDismissed,
        isFetchingInvoice,
        isRotatingAddress,
        paymentUri.toString(),
      ];
}

final class ReceiveFailure extends ReceiveState {
  const ReceiveFailure();

  String get message => S.current.receive_error_address_list;
}
