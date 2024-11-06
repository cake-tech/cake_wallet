import 'package:cake_wallet/buy/buy_provider.dart';
import 'package:cake_wallet/buy/payment_method.dart';
import 'package:cake_wallet/core/selectable_option.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/entities/provider_types.dart';
import 'package:cake_wallet/exchange/limits.dart';
import 'package:cw_core/crypto_currency.dart';

enum ProviderRecommendation { bestRate, lowKyc, successRate }

extension RecommendationTitle on ProviderRecommendation {
  String get title {
    switch (this) {
      case ProviderRecommendation.bestRate:
        return 'BEST RATE';
      case ProviderRecommendation.lowKyc:
        return 'LOW KYC';
      case ProviderRecommendation.successRate:
        return 'SUCCESS RATE';
    }
  }
}

ProviderRecommendation? getRecommendationFromString(String title) {
  switch (title) {
    case 'BEST RATE':
      return ProviderRecommendation.bestRate;
    case 'LowKyc':
      return ProviderRecommendation.lowKyc;
    case 'SuccessRate':
      return ProviderRecommendation.successRate;
    default:
      return null;
  }
}

class Quote extends SelectableOption {
  Quote({
    required this.rate,
    required this.feeAmount,
    required this.networkFee,
    required this.transactionFee,
    required this.payout,
    required this.provider,
    required this.paymentType,
    required this.recommendations,
    this.isBuyAction = true,
    this.quoteId,
    this.rampId,
    this.rampName,
    this.rampIconPath,
    this.limits,
  }) : super(title: provider.isAggregator ? rampName ?? '' : provider.title);

  final double rate;
  final double feeAmount;
  final double networkFee;
  final double transactionFee;
  final double payout;
  final PaymentType paymentType;
  final BuyProvider provider;
  final String? quoteId;
  final List<ProviderRecommendation> recommendations;
  String? rampId;
  String? rampName;
  String? rampIconPath;
  bool _isSelected = false;
  bool _isBestRate = false;
  bool isBuyAction;
  Limits? limits;

  late FiatCurrency _fiatCurrency;
  late CryptoCurrency _cryptoCurrency;


  bool get isSelected => _isSelected;
  bool get isBestRate => _isBestRate;
  FiatCurrency get fiatCurrency => _fiatCurrency;
  CryptoCurrency get cryptoCurrency => _cryptoCurrency;

  @override
  bool get isOptionSelected => this._isSelected;

  @override
  String get lightIconPath =>
      provider.isAggregator ? rampIconPath ?? provider.lightIcon : provider.lightIcon;

  @override
  String get darkIconPath =>
      provider.isAggregator ? rampIconPath ?? provider.darkIcon : provider.darkIcon;

  @override
  List<String> get badges => recommendations.map((e) => e.title).toList();

  @override
  String get topLeftSubTitle =>
      this.rate > 0 ? '1 $cryptoName = ${rate.toStringAsFixed(2)} $fiatName' : '';

  @override
  String get bottomLeftSubTitle {
    if (limits != null) {
      final min = limits!.min;
      final max = limits!.max;
      return 'min: ${min} ${fiatCurrency.toString()} | max: ${max == double.infinity ? '' : '${max} ${fiatCurrency.toString()}'}';
    }
    return '';
  }

  String get fiatName => isBuyAction ? fiatCurrency.toString() : cryptoCurrency.toString();

  String get cryptoName => isBuyAction ? cryptoCurrency.toString() : fiatCurrency.toString();

  @override
  String? get topRightSubTitle => '';

  @override
  String get topRightSubTitleLightIconPath => provider.isAggregator ? provider.lightIcon : '';

  @override
  String get topRightSubTitleDarkIconPath => provider.isAggregator ? provider.darkIcon : '';

  String get quoteTitle => '${provider.title} - ${paymentType.name}';

  String get formatedFee => '$feeAmount ${isBuyAction ? fiatCurrency : cryptoCurrency}';

  set setIsSelected(bool isSelected) => _isSelected = isSelected;
  set setIsBestRate(bool isBestRate) => _isBestRate = isBestRate;
  set setFiatCurrency(FiatCurrency fiatCurrency) => _fiatCurrency = fiatCurrency;
  set setCryptoCurrency(CryptoCurrency cryptoCurrency) => _cryptoCurrency = cryptoCurrency;
  set setLimits(Limits limits) => this.limits = limits;

  factory Quote.fromOnramperJson(Map<String, dynamic> json, bool isBuyAction,
      Map<String, dynamic> metaData, PaymentType paymentType) {
    final rate = _toDouble(json['rate']) ?? 0.0;
    final networkFee = _toDouble(json['networkFee']) ?? 0.0;
    final transactionFee = _toDouble(json['transactionFee']) ?? 0.0;
    final feeAmount = double.parse((networkFee + transactionFee).toStringAsFixed(2));

    final rampId = json['ramp'] as String? ?? '';
    final rampData = metaData[rampId] ?? {};
    final rampName = rampData['displayName'] as String? ?? '';
    final rampIconPath = rampData['svg'] as String? ?? '';

    final recommendations = json['recommendations'] != null
        ? List<String>.from(json['recommendations'] as List<dynamic>)
        : <String>[];

    final enumRecommendations = recommendations
        .map((e) => getRecommendationFromString(e))
        .whereType<ProviderRecommendation>()
        .toList();

    final availablePaymentMethods = json['availablePaymentMethods'] as List<dynamic>? ?? [];
    double minLimit = 0.0;
    double maxLimit = double.infinity;

    for (var paymentMethod in availablePaymentMethods) {
      if (paymentMethod is Map<String, dynamic>) {
        final details = paymentMethod['details'] as Map<String, dynamic>?;

        if (details != null) {
          final limits = details['limits'] as Map<String, dynamic>?;

          if (limits != null && limits.isNotEmpty) {
            final firstLimitEntry = limits.values.first as Map<String, dynamic>?;
            if (firstLimitEntry != null) {
              minLimit = _toDouble(firstLimitEntry['min'])?.roundToDouble() ?? 0.0;
              maxLimit = _toDouble(firstLimitEntry['max'])?.roundToDouble() ?? double.infinity;
              break;
            }
          }
        }
      }
    }

    return Quote(
      rate: rate,
      feeAmount: feeAmount,
      networkFee: networkFee,
      transactionFee: transactionFee,
      payout: json['payout'] as double? ?? 0.0,
      rampId: rampId,
      rampName: rampName,
      rampIconPath: rampIconPath,
      paymentType: paymentType,
      quoteId: json['quoteId'] as String? ?? '',
      recommendations: enumRecommendations,
      provider: ProvidersHelper.getProviderByType(ProviderType.onramper)!,
      isBuyAction: isBuyAction,
      limits: Limits(min: minLimit, max: maxLimit),
    );
  }

  factory Quote.fromMoonPayJson(
      Map<String, dynamic> json, bool isBuyAction, PaymentType paymentType) {
    final rate = isBuyAction
        ? json['quoteCurrencyPrice'] as double? ?? 0.0
        : json['baseCurrencyPrice'] as double? ?? 0.0;
    final fee = _toDouble(json['feeAmount']) ?? 0.0;
    final networkFee = _toDouble(json['networkFeeAmount']) ?? 0.0;
    final transactionFee = _toDouble(json['extraFeeAmount']) ?? 0.0;
    final feeAmount = double.parse((fee + networkFee + transactionFee).toStringAsFixed(2));

    final baseCurrency = json['baseCurrency'] as Map<String, dynamic>?;

    double minLimit = 0.0;
    double maxLimit = double.infinity;

    if (baseCurrency != null) {
      minLimit = _toDouble(baseCurrency['minAmount']) ?? minLimit;
      maxLimit = _toDouble(baseCurrency['maxAmount']) ?? maxLimit;
    }

    return Quote(
      rate: rate,
      feeAmount: feeAmount,
      networkFee: networkFee,
      transactionFee: transactionFee,
      payout: _toDouble(json['quoteCurrencyAmount']) ?? 0.0,
      paymentType: paymentType,
      recommendations: [],
      quoteId: json['signature'] as String? ?? '',
      provider: ProvidersHelper.getProviderByType(ProviderType.moonpay)!,
      isBuyAction: isBuyAction,
      limits: Limits(min: minLimit, max: maxLimit),
    );
  }

  factory Quote.fromDFXJson(
    Map<String, dynamic> json,
    bool isBuyAction,
    PaymentType paymentType,
  ) {
    final rate = _toDouble(json['exchangeRate']) ?? 0.0;
    final fees = json['fees'] as Map<String, dynamic>;

    final minVolume = _toDouble(json['minVolume']) ?? 0.0;
    final maxVolume = _toDouble(json['maxVolume']) ?? double.infinity;

    return Quote(
      rate: isBuyAction ? rate : 1 / rate,
      feeAmount: _toDouble(json['feeAmount']) ?? 0.0,
      networkFee: _toDouble(fees['network']) ?? 0.0,
      transactionFee: _toDouble(fees['rate']) ?? 0.0,
      payout: _toDouble(json['payout']) ?? 0.0,
      paymentType: paymentType,
      recommendations: [ProviderRecommendation.lowKyc],
      provider: ProvidersHelper.getProviderByType(ProviderType.dfx)!,
      isBuyAction: isBuyAction,
      limits: Limits(min: minVolume, max: maxVolume),
    );
  }

  factory Quote.fromRobinhoodJson(
      Map<String, dynamic> json, bool isBuyAction, PaymentType paymentType) {
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
      paymentType: paymentType,
      recommendations: [],
      provider: ProvidersHelper.getProviderByType(ProviderType.robinhood)!,
      isBuyAction: isBuyAction,
      limits: Limits(min: 0.0, max: double.infinity),
    );
  }

  factory Quote.fromMeldJson(Map<String, dynamic> json, bool isBuyAction, PaymentType paymentType) {
    final quotes = json['quotes'][0] as Map<String, dynamic>;
    return Quote(
      rate: quotes['exchangeRate'] as double? ?? 0.0,
      feeAmount: quotes['totalFee'] as double? ?? 0.0,
      networkFee: quotes['networkFee'] as double? ?? 0.0,
      transactionFee: quotes['transactionFee'] as double? ?? 0.0,
      payout: quotes['payout'] as double? ?? 0.0,
      paymentType: paymentType,
      recommendations: [],
      provider: ProvidersHelper.getProviderByType(ProviderType.meld)!,
      isBuyAction: isBuyAction,
      limits: Limits(min: 0.0, max: double.infinity),
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
