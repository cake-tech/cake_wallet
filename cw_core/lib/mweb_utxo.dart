import 'package:cw_core/hive_type_ids.dart';
import 'package:hive/hive.dart';

// part 'mweb_utxo.g.dart';

@HiveType(typeId: MWEB_UTXO_TYPE_ID)
class MwebUtxo extends HiveObject {
  MwebUtxo({
    required this.address,
    this.accountIndex,
    required this.label,
  });

  static const typeId = MWEB_UTXO_TYPE_ID;
  static const boxName = 'MwebUtxo';

  @HiveField(0)
  int? accountIndex;

  @HiveField(1, defaultValue: '')
  String address;

  @HiveField(2, defaultValue: '')
  String label;
}
