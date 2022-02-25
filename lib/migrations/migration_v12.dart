import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/migrations/commons.dart';
import 'package:cw_core/node.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MigrationV12 {
  static Future<void> run() async {
    final nodes = getIt.get<Box<Node>>();
    final sharedPreferences = getIt.get<SharedPreferences>();
    await checkCurrentNodes(nodes, sharedPreferences);
  }
}
