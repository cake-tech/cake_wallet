import 'package:hive/hive.dart';

part 'template.g.dart';

@HiveType(typeId: Template.typeId)
class Template extends HiveObject {
  Template({this.name,this.isCurrencySelected, this.address, this.cryptoCurrency, this.amount, this.fiatCurrency, this.amountFiat});

  static const typeId = 6;
  static const boxName = 'Template';

  @HiveField(0)
  String name;

  @HiveField(1)
  String address;

  @HiveField(2)
  String cryptoCurrency;

  @HiveField(3)
  String amount;

  @HiveField(4)
  String fiatCurrency;

  @HiveField(5)
  bool isCurrencySelected;

  @HiveField(6)
  String amountFiat;
}

