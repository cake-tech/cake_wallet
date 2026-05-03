import 'package:cake_wallet/core/wallet_creation_service.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OmniChainWalletCreationService {
  OmniChainWalletCreationService({
    required this.walletCreationService,
    required this.sharedPreferences,
  });

  final WalletCreationService walletCreationService;
  final SharedPreferences sharedPreferences;

  static const _groupNameKeyPrefix = 'wallet_group_name_';

  List<String> getAllCustomGroupNames() {
    final result = <String>[];

    for (final key in sharedPreferences.getKeys()) {
      if (!key.startsWith(_groupNameKeyPrefix)) continue;

      final value = sharedPreferences.getString(key);
      if (value != null && value.trim().isNotEmpty) {
        result.add(value.trim());
      }
    }

    return result;
  }

  bool groupNameExists(String name) {
    final groupName = name.toLowerCase();
    return getAllCustomGroupNames().any(
          (name) => name.toLowerCase() == groupName,
    );
  }

  Future<void> setGroupNameForKey(String groupKey, String name) async {
    await sharedPreferences.setString(
      '$_groupNameKeyPrefix$groupKey',
      name,
    );
  }

  Future<void> createGroup({
    required String groupName,
    required Set<WalletType> types,
  }) async {
    // TODO later
  }
}