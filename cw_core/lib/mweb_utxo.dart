import 'package:cw_core/hive_type_ids.dart';
import 'package:hive/hive.dart';

part 'mweb_utxo.g.dart';

@HiveType(typeId: MWEB_UTXO_TYPE_ID)
class MwebUtxo extends HiveObject {
  MwebUtxo({
    required this.height,
    required this.value,
    required this.address,
    required this.outputId,
    required this.blockTime,
    this.spent = false,
  });

  static const typeId = MWEB_UTXO_TYPE_ID;
  static const boxName = 'MwebUtxo';

  @HiveField(0)
  int height;

  @HiveField(1)
  int value;

  @HiveField(2)
  String address;

  @HiveField(3)
  String outputId;

  @HiveField(4)
  int blockTime;

  @HiveField(5, defaultValue: false)
  bool spent;
}
