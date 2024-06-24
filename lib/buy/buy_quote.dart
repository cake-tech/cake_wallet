import 'package:cake_wallet/buy/buy_provider.dart';
import 'package:cake_wallet/core/selectable_option.dart';
import 'package:cake_wallet/entities/provider_types.dart';

class Quote implements SelectableOption {
  final double rate;
  final double networkFee;
  final double transactionFee;
  final double payout;
  final String ramp;
  final String paymentMethod;
  final String quoteId;
  final List<String> recommendations;
  final List<Map<String, dynamic>> errors;
  final BuyProvider? provider;

  Quote({
    required this.rate,
    required this.networkFee,
    required this.transactionFee,
    required this.payout,
    required this.ramp,
    required this.paymentMethod,
    required this.quoteId,
    required this.recommendations,
    required this.errors,
    required this.provider,
  });

  @override
  String get title => provider?.title ?? '';

  @override
  String get iconPath => provider?.lightIcon ?? '';

  @override
  String get description => provider?.providerDescription ?? '';

  @override
  String get badgeTitle => '';

  factory Quote.fromJson(Map<String, dynamic> json, ProviderType providerType) {
    return Quote(
      rate: (json['rate'] as num?)?.toDouble() ?? 0.0,
      networkFee: (json['networkFee'] as num?)?.toDouble() ?? 0.0,
      transactionFee: (json['transactionFee'] as num?)?.toDouble() ?? 0.0,
      payout: (json['payout'] as num?)?.toDouble() ?? 0.0,
      ramp: json['ramp'] as String? ?? '',
      paymentMethod: json['paymentMethod'] as String? ?? '',
      quoteId: json['quoteId'] as String? ?? '',
      recommendations: (json['recommendations'] as List<dynamic>?)
          ?.map((item) => item as String)
          .toList() ??
          [],
      errors: (json['errors'] as List<dynamic>?)
          ?.map((item) => item as Map<String, dynamic>)
          .toList() ??
          [],
      provider: ProvidersHelper.getProviderByType(providerType),
    );
  }
  
}