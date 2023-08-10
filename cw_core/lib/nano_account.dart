import 'package:hive/hive.dart';

part 'nano_account.g.dart';

@HiveType(typeId: NanoAccount.typeId)
class NanoAccount extends HiveObject {
  NanoAccount({required this.label, required this.id, this.balance, this.isSelected = false});

  static const typeId = 13;

  @HiveField(0)
  String label;

  @HiveField(1)
  final int id;

  @HiveField(2)
  bool isSelected;

  @HiveField(3)
  String? balance;
}
