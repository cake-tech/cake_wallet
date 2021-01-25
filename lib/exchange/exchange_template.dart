import 'package:hive/hive.dart';

part 'exchange_template.g.dart';

@HiveType(typeId: ExchangeTemplate.typeId)
class ExchangeTemplate extends HiveObject {
  ExchangeTemplate({
    this.amount,
    this.depositCurrency,
    this.receiveCurrency,
    this.provider,
    this.depositAddress,
    this.receiveAddress
  });

  static const typeId = 7;
  static const boxName = 'ExchangeTemplate';

  @HiveField(0)
  String amount;

  @HiveField(1)
  String depositCurrency;

  @HiveField(2)
  String receiveCurrency;

  @HiveField(3)
  String provider;

  @HiveField(4)
  String depositAddress;

  @HiveField(5)
  String receiveAddress;
}