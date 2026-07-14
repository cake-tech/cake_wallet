import 'package:cake_wallet/core/utilities.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/node_list.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Map<WalletType, String> nodePreferenceKeys = {
  WalletType.monero: PreferencesKey.currentNodeIdKey,
  WalletType.bitcoin: PreferencesKey.currentBitcoinElectrumSererIdKey,
  WalletType.litecoin: PreferencesKey.currentLitecoinElectrumSererIdKey,
  WalletType.haven: PreferencesKey.currentHavenNodeIdKey,
  WalletType.ethereum: PreferencesKey.currentEthereumNodeIdKey,
  WalletType.polygon: PreferencesKey.currentPolygonNodeIdKey,
  WalletType.base: PreferencesKey.currentBaseNodeIdKey,
  WalletType.arbitrum: PreferencesKey.currentArbitrumNodeIdKey,
  WalletType.bsc: PreferencesKey.currentBscNodeIdKey,
  WalletType.nano: PreferencesKey.currentNanoNodeIdKey,
  WalletType.decred: PreferencesKey.currentDecredNodeIdKey,
  WalletType.bitcoinCash: PreferencesKey.currentBitcoinCashNodeIdKey,
  WalletType.dogecoin: PreferencesKey.currentDogecoinNodeIdKey,
  WalletType.solana: PreferencesKey.currentSolanaNodeIdKey,
  WalletType.tron: PreferencesKey.currentTronNodeIdKey,
  WalletType.wownero: PreferencesKey.currentWowneroNodeIdKey,
  WalletType.zano: PreferencesKey.currentZanoNodeIdKey,
  WalletType.zcash: PreferencesKey.currentZcashNodeIdKey,
};

const Map<WalletType, String> powNodePreferenceKeys = {
  WalletType.nano: PreferencesKey.currentNanoPowNodeIdKey
};

Future<void> checkNodeForWalletType(SharedPreferences sharedPreferences,
    SettingsStore settingsStore, WalletType type, bool isPow) async {
  final preferenceKey = isPow ? powNodePreferenceKeys[type] : nodePreferenceKeys[type];

  if (preferenceKey == null) {
    return;
  }

  final currentId = await sharedPreferences.getInt(preferenceKey);

  final nodes =
      isPow ? await Node.getAllForWalletTypePow(type) : await Node.getAllForWalletType(type);
  final currentNode = nodes.firstWhereOrNull((item) => item.id == currentId);

  if (currentNode == null) {
    final newNode = (isPow
            ? await Node.getDefaultPowForWalletType(type)
            : await Node.getDefaultForWalletType(type)) ??
        await getDefaultNodeFromFiles(type, isPow: isPow);
    final newId = await newNode.save();
    sharedPreferences.setInt(preferenceKey, newId);
    settingsStore.nodes[type] = newNode;
  } else {
    settingsStore.nodes[type] = currentNode;
  }
}

Future<void> checkCurrentNodes(
    SharedPreferences sharedPreferences, SettingsStore settingsStore) async {
  for (final walletType in nodePreferenceKeys.keys) {
    await checkNodeForWalletType(sharedPreferences, settingsStore, walletType, false);
  }

  for (final walletType in powNodePreferenceKeys.keys) {
    await checkNodeForWalletType(sharedPreferences, settingsStore, walletType, true);
  }
}
