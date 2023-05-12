import 'package:hive/hive.dart';

part 'address_info.g.dart';

@HiveType(typeId: AddressInfo.typeId)
class AddressInfo extends HiveObject {
  AddressInfo({required this.address, this.accountIndex, required this.label});

  static const typeId = 11;
  static const boxName = 'AddressInfo';

  @HiveField(0)
  int? accountIndex;

  @HiveField(1, defaultValue: '')
  String address;

  @HiveField(2, defaultValue: '')
  String label;
}