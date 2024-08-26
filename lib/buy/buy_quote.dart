import 'package:cake_wallet/buy/buy_provider.dart';
import 'package:cake_wallet/core/selectable_option.dart';
import 'package:cake_wallet/entities/provider_types.dart';

class Quote extends SelectableOption {
  final double rate;
  final double feeAmount;
  final double networkFee;
  final double transactionFee;
  final double payout;
  final String paymentMethod;
  final BuyProvider? provider;
  final String? quoteId;
  final String? ramp;
  String sourceCurrency = '';
  String destinationCurrency = '';
  bool isSelected = false;
  bool isBestRate = false;
  bool isLowKYC = false;
  bool isBuyAction;

  Quote({
    required this.rate,
    required this.feeAmount,
    required this.networkFee,
    required this.transactionFee,
    required this.payout,
    required this.provider,
    required this.paymentMethod,
    this.isBuyAction = true,
    this.quoteId,
    this.ramp,
  });

  @override
  String get title => provider?.title ?? '';

  @override
  bool get isOptionSelected => this.isSelected;

  @override
  String get iconPath => provider?.lightIcon ?? '';

  @override
  String? get firstBadgeTitle => isBestRate ? 'BEST RATE' : null;

  @override
  String? get secondBadgeTitle => isLowKYC  ? 'LOW KYC' : null;

  @override
  String? get subTitle => this.rate > 0
      ? '1 ${isBuyAction ? destinationCurrency : sourceCurrency} = ${rate.toStringAsFixed(2)} ${isBuyAction ? sourceCurrency : destinationCurrency }'
      : null; //total fee = $formatedFee


  String get formatedFee => '$feeAmount ${isBuyAction ? sourceCurrency : destinationCurrency}';

  void set setIsSelected(bool isSelected) => this.isSelected = isSelected;

  void set setIsBestRate(bool isBestRate) => this.isBestRate = isBestRate;

  void set setIsLowKYC(bool isLowKYC) => this.isLowKYC = isLowKYC;

  void set setSourceCurrency(String sourceCurrency) => this.sourceCurrency = sourceCurrency;

  void set setDestinationCurrency(String destinationCurrency) =>
      this.destinationCurrency = destinationCurrency;

  factory Quote.fromOnramperJson(Map<String, dynamic> json, ProviderType providerType, bool isBuyAction) {
    final rate = _toDouble(json['rate']) ?? 0.0;
    final networkFee = _toDouble(json['networkFee']) ?? 0.0;
    final transactionFee = _toDouble(json['transactionFee']) ?? 0.0;
    final feeAmount = double.parse((networkFee + transactionFee).toStringAsFixed(2));
    return Quote(
      rate: rate,
      feeAmount: feeAmount,
      networkFee: networkFee,
      transactionFee: transactionFee,
      payout: json['payout'] as double? ?? 0.0,
      ramp: json['ramp'] as String? ?? '',
      paymentMethod: json['paymentMethod'] as String? ?? '',
      quoteId: json['quoteId'] as String? ?? '',
      provider: ProvidersHelper.getProviderByType(providerType),
      isBuyAction: isBuyAction,
    );
  }

  factory Quote.fromMoonPayJson(
      Map<String, dynamic> json, ProviderType providerType, bool isBuyAction) {
    final rate = isBuyAction
        ? json['quoteCurrencyPrice'] as double? ?? 0.0
        : json['baseCurrencyPrice'] as double? ?? 0.0;
    final fee = _toDouble(json['feeAmount']) ?? 0.0;
    final networkFee = _toDouble(json['networkFeeAmount']) ?? 0.0;
    final transactionFee = _toDouble(json['extraFeeAmount']) ?? 0.0;
    final feeAmount = double.parse((fee + networkFee + transactionFee).toStringAsFixed(2));
    return Quote(
      rate: rate,
      feeAmount: feeAmount,
      networkFee: networkFee,
      transactionFee: transactionFee,
      payout: _toDouble(json['quoteCurrencyAmount']) ?? 0.0,
      paymentMethod: json['paymentMethod'] as String? ?? '',
      quoteId: json['signature'] as String? ?? '',
      provider: ProvidersHelper.getProviderByType(providerType),
      isBuyAction: isBuyAction,
    );
  }

  factory Quote.fromDFXJson(
      Map<String, dynamic> json, ProviderType providerType, bool isBuyAction) {
    final rate = _toDouble(json['exchangeRate']) ?? 0.0;
    final fees = json['fees'] as Map<String, dynamic>;
    return Quote(
      rate: isBuyAction ? rate : 1 / rate,
      feeAmount: json['feeAmount'] as double? ?? 0.0,
      networkFee: fees['network'] as double? ?? 0.0,
      transactionFee: fees['rate'] as double? ?? 0.0,
      payout: json['payout'] as double? ?? 0.0,
      paymentMethod: json['paymentMethod'] as String? ?? '',
      provider: ProvidersHelper.getProviderByType(providerType),
      isBuyAction: isBuyAction,
    );
  }

  factory Quote.fromRobinhoodJson(Map<String, dynamic> json, ProviderType providerType, bool isBuyAction) {
    final networkFee = json['networkFee'] as Map<String, dynamic>;
    final processingFee = json['processingFee'] as Map<String, dynamic>;
    final networkFeeAmount = _toDouble(networkFee['fiatAmount']) ?? 0.0;
    final transactionFeeAmount = _toDouble(processingFee['fiatAmount']) ?? 0.0;
    final feeAmount = double.parse((networkFeeAmount + transactionFeeAmount).toStringAsFixed(2));

    return Quote(
      rate: _toDouble(json['price']) ?? 0.0,
      feeAmount: feeAmount,
      networkFee: _toDouble(networkFee['fiatAmount']) ?? 0.0,
      transactionFee: _toDouble(processingFee['fiatAmount']) ?? 0.0,
      payout: _toDouble(json['cryptoAmount']) ?? 0.0,
      paymentMethod: json['paymentMethod'] as String? ?? '',
      provider: ProvidersHelper.getProviderByType(providerType),
      isBuyAction: isBuyAction,
    );
  }

  factory Quote.fromMeldJson(Map<String, dynamic> json, ProviderType providerType, bool isBuyAction) {
    final quotes = json['quotes'][0] as Map<String, dynamic>;
    return Quote(
      rate: quotes['exchangeRate'] as double? ?? 0.0,
      feeAmount: quotes['totalFee'] as double? ?? 0.0,
      networkFee: quotes['networkFee'] as double? ?? 0.0,
      transactionFee: quotes['transactionFee'] as double? ?? 0.0,
      payout: quotes['payout'] as double? ?? 0.0,
      paymentMethod: quotes['paymentMethodType'] as String? ?? '',
      provider: ProvidersHelper.getProviderByType(providerType),
      isBuyAction: isBuyAction,
    );
  }

  static double? _toDouble(dynamic value) {
    if (value is int) {
      return value.toDouble();
    } else if (value is double) {
      return value;
    } else if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }
}
