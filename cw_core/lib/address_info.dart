import 'package:cw_core/hive_type_ids.dart';
import 'package:hive/hive.dart';

part 'address_info.g.dart';

@HiveType(typeId: ADDRESS_INFO_TYPE_ID)
class AddressInfo extends HiveObject {
  AddressInfo({required this.address, this.accountIndex, required this.label});

  static const typeId = ADDRESS_INFO_TYPE_ID;
  static const boxName = 'AddressInfo';

  @HiveField(0)
  int? accountIndex;

  @HiveField(1, defaultValue: '')
  String address;

  @HiveField(2, defaultValue: '')
  String label;
}
