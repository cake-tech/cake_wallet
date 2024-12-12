import 'package:cw_core/hive_type_ids.dart';
import 'package:hive/hive.dart';

part 'haven_seed_store.g.dart';

@HiveType(typeId: HavenSeedStore.typeId)
class HavenSeedStore extends HiveObject {
  HavenSeedStore({required this.id, this.seed});

  static const typeId = HAVEN_SEED_STORE_TYPE_ID;
  static const boxName = 'HavenSeedStore';
  static const boxKey = 'havenSeedStoreKey';

  @HiveField(0, defaultValue: '')
  String id;

  @HiveField(2)
  String? seed;
}
