import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cake_wallet/migrations/commons.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MigrationV13 {
  static Future<void> run() async {
    final nodes = getIt.get<Box<Node>>();
    final sharedPreferences = getIt.get<SharedPreferences>();
    await resetBitcoinElectrumServer(nodes, sharedPreferences);
  }

  static Future<void> resetBitcoinElectrumServer(
      Box<Node> nodeSource, SharedPreferences sharedPreferences) async {
    final currentElectrumSeverId = sharedPreferences
        .getInt(PreferencesKey.currentBitcoinElectrumSererIdKey);
    final oldElectrumServer = nodeSource.values.firstWhere(
        (node) => node.uri.toString().contains('electrumx.cakewallet.com'),
        orElse: () => null);
    var cakeWalletNode = nodeSource.values.firstWhere(
        (node) => node.uri.toString() == cakeWalletBitcoinElectrumUri,
        orElse: () => null);

    if (cakeWalletNode == null) {
      cakeWalletNode =
          Node(uri: cakeWalletBitcoinElectrumUri, type: WalletType.bitcoin);
      await nodeSource.add(cakeWalletNode);
    }

    if (currentElectrumSeverId == oldElectrumServer?.key) {
      await sharedPreferences.setInt(
          PreferencesKey.currentBitcoinElectrumSererIdKey,
          cakeWalletNode.key as int);
    }

    await oldElectrumServer?.delete();
  }
}
