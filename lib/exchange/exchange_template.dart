import 'package:hive/hive.dart';

part 'exchange_template.g.dart';

@HiveType(typeId: ExchangeTemplate.typeId)
class ExchangeTemplate extends HiveObject {
  ExchangeTemplate({
    required this.amountRaw,
    required this.depositCurrencyRaw,
    required this.receiveCurrencyRaw,
    required this.providerRaw,
    required this.depositAddressRaw,
    required this.receiveAddressRaw
  });

  static const typeId = 7;
  static const boxName = 'ExchangeTemplate';

  @HiveField(0)
  String? amountRaw;

  @HiveField(1)
  String? depositCurrencyRaw;

  @HiveField(2)
  String? receiveCurrencyRaw;

  @HiveField(3)
  String? providerRaw;

  @HiveField(4)
  String? depositAddressRaw;

  @HiveField(5)
  String? receiveAddressRaw;

  String get amount => amountRaw ?? '';

  String get depositCurrency => depositCurrencyRaw ?? '';

  String get receiveCurrency => receiveCurrencyRaw ?? '';

  String get provider => providerRaw ?? '';

  String get depositAddress => depositAddressRaw ?? '';

  String get receiveAddress => receiveAddressRaw ?? '';
}