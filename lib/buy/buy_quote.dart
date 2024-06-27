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
  bool isSelected = false;
  bool isBestRate = false;


  Quote({
    required this.rate,
    required this.feeAmount,
    required this.networkFee,
    required this.transactionFee,
    required this.payout,
    required this.provider,
    required this.paymentMethod,
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
  String get description => provider?.providerDescription ?? '';

  @override
  String? get firstBadgeName => isBestRate ? 'Best rate' : null;

  @override
  String? get secondBadgeName => provider?.isAggregator ?? false ? 'Aggregator' : null;

  @override
  String? get subTitle =>  this.rate > 0 ?  '1 ${'BTC'} = ${(rate).toStringAsFixed(2)} ${'USD'}' : null;


  void set setIsSelected(bool isSelected) => this.isSelected = isSelected;
  void set setIsBestRate(bool isBestRate) => this.isBestRate = isBestRate;

  factory Quote.fromOnramperJson(Map<String, dynamic> json, ProviderType providerType) {
    final networkFee = json['networkFee'] as double? ?? 0.0;
    final transactionFee = (json['transactionFee'] as int?)?.toDouble() ?? 0.0;
    return Quote(
      rate: json['rate'] as double? ?? 0.0,
      feeAmount: networkFee + transactionFee,
      networkFee: networkFee,
      transactionFee: transactionFee,
      payout: json['payout'] as double? ?? 0.0,
      ramp: json['ramp'] as String? ?? '',
      paymentMethod: json['paymentMethod'] as String? ?? '',
      quoteId: json['quoteId'] as String? ?? '',
      provider: ProvidersHelper.getProviderByType(providerType),
    );
  }

  factory Quote.fromMoonPayJson(Map<String, dynamic> json, ProviderType providerType) {
    final fee = json['feeAmount'] as double? ?? 0.0;
    final networkFee = json['networkFeeAmount'] as double? ?? 0.0;
    final transactionFee = (json['extraFeeAmount'] as int?)?.toDouble() ?? 0.0;
    return Quote(
      rate: json['quoteCurrencyPrice'] as double? ?? 0.0,
      feeAmount: fee + networkFee + transactionFee,
      networkFee: networkFee,
      transactionFee: transactionFee,
      payout: json['quoteCurrencyAmount'] as double? ?? 0.0,
      paymentMethod: json['paymentMethod'] as String? ?? '',
      quoteId: json['signature'] as String? ?? '',
      provider: ProvidersHelper.getProviderByType(providerType),
    );
  }

  factory Quote.fromDFXJson(Map<String, dynamic> json, ProviderType providerType) {
    final fees = json['fees'] as Map<String, dynamic>;
    return Quote(
      rate: json['exchangeRate'] as double? ?? 0.0,
      feeAmount: json['feeAmount'] as double? ?? 0.0,
      networkFee: fees['network'] as double? ?? 0.0 ,
      transactionFee: fees['rate'] as double? ?? 0.0,
      payout: json['payout'] as double? ?? 0.0,
      paymentMethod: json['paymentMethod'] as String? ?? '',
      provider: ProvidersHelper.getProviderByType(providerType),
    );
  }
}
