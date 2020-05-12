import 'package:hive/hive.dart';

part 'template.g.dart';

@HiveType()
class Template extends HiveObject {
  Template({this.name, this.address, this.cryptoCurrency, this.amount});

  static const boxName = 'Template';

  @HiveField(0)
  String name;

  @HiveField(1)
  String address;

  @HiveField(2)
  String cryptoCurrency;

  @HiveField(3)
  String amount;
}