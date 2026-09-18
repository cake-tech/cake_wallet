import "package:cw_core/coin_control/coin_notes_store.dart";
import "package:cw_core/coin_control/frozen_coins_store.dart";

/// An in-memory [FrozenCoinsStore] for tests.
///
/// Lets the coin control logic be exercised without a database. Not for
/// production use: nothing here survives the process.
class FakeFrozenCoinsStore implements FrozenCoinsStore {
  final Map<int, Map<String, bool>> _byWallet = {};

  /// Number of stored records, across all wallets.
  int get recordCount => _byWallet.values.fold(0, (sum, rows) => sum + rows.length);

  @override
  Future<Set<String>> frozenIds(int walletInfoId) async {
    final rows = _byWallet[walletInfoId] ?? const <String, bool>{};
    return rows.entries.where((entry) => entry.value).map((entry) => entry.key).toSet();
  }

  @override
  Future<void> setFrozen(int walletInfoId, String id, bool frozen) async =>
      _byWallet.putIfAbsent(walletInfoId, () => {})[id] = frozen;

  @override
  Future<void> deleteWallet(int walletInfoId) async => _byWallet.remove(walletInfoId);
}

/// An in-memory [CoinNotesStore] for tests. See [FakeFrozenCoinsStore].
class FakeCoinNotesStore implements CoinNotesStore {
  final Map<int, Map<String, String>> _byWallet = {};

  /// Number of stored records, across all wallets.
  int get recordCount => _byWallet.values.fold(0, (sum, rows) => sum + rows.length);

  @override
  Future<Map<String, String>> forWallet(int walletInfoId) async =>
      Map.of(_byWallet[walletInfoId] ?? const {});

  @override
  Future<void> save(int walletInfoId, String id, String note) async =>
      _byWallet.putIfAbsent(walletInfoId, () => {})[id] = note;

  @override
  Future<void> deleteWallet(int walletInfoId) async => _byWallet.remove(walletInfoId);
}
