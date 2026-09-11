import "package:cw_core/coin_control/coin_notes_store.dart";
import "package:cw_core/coin_control/frozen_coins_store.dart";

/// An in-memory [FrozenCoinsStore] for tests.
///
/// Lets the coin control logic be exercised without a database. Not for
/// production use: nothing here survives the process.
class FakeFrozenCoinsStore implements FrozenCoinsStore {
  final Map<String, Map<String, bool>> _byWallet = {};

  /// Number of stored records, across all wallets.
  int get recordCount => _byWallet.values.fold(0, (sum, rows) => sum + rows.length);

  @override
  Future<Set<String>> frozenIds(String walletId) async {
    final rows = _byWallet[walletId] ?? const <String, bool>{};
    return rows.entries.where((entry) => entry.value).map((entry) => entry.key).toSet();
  }

  @override
  Future<void> setFrozen(String walletId, String id, bool frozen) async =>
      _byWallet.putIfAbsent(walletId, () => {})[id] = frozen;

  @override
  Future<void> deleteWallet(String walletId) async => _byWallet.remove(walletId);
}

/// An in-memory [CoinNotesStore] for tests. See [FakeFrozenCoinsStore].
class FakeCoinNotesStore implements CoinNotesStore {
  final Map<String, Map<String, String>> _byWallet = {};

  /// Number of stored records, across all wallets.
  int get recordCount => _byWallet.values.fold(0, (sum, rows) => sum + rows.length);

  @override
  Future<Map<String, String>> forWallet(String walletId) async =>
      Map.of(_byWallet[walletId] ?? const {});

  @override
  Future<void> save(String walletId, String id, String note) async =>
      _byWallet.putIfAbsent(walletId, () => {})[id] = note;

  @override
  Future<void> deleteWallet(String walletId) async => _byWallet.remove(walletId);
}
