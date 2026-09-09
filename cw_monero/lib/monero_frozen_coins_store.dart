import "package:cw_core/coin_control/frozen_coins_store.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:cw_monero/api/coins_info.dart";

class MoneroFrozenCoinsStore extends FrozenCoinsStore {
  MoneroFrozenCoinsStore({
    Future<void> Function(int index) freeze = freezeCoin,
    Future<void> Function(int index) thaw = thawCoin,
  })  : _freeze = freeze,
        _thaw = thaw;

  // these are function pointers so they can be mocked in unit tests
  final Future<void> Function(int index) _freeze;
  final Future<void> Function(int index) _thaw;

  final Map<String, bool> _frozen = {};
  final Map<String, int> _indexes = {};

  void beginRefresh() {
    _frozen.clear();
    _indexes.clear();
  }

  void record({required String keyImage, required int index, required bool frozen}) {
    _frozen[keyImage] = frozen;
    _indexes[keyImage] = index;
  }

  @override
  Future<Set<String>> frozenIds(String walletId) async =>
      _frozen.entries.where((entry) => entry.value).map((entry) => entry.key).toSet();

  @override
  Future<void> setFrozen(String walletId, String id, bool frozen) async {
    final index = _indexes[id];
    if (index == null) {
      // Nothing to act on in wallet2, so the flag is cached alone and the next
      // refresh replaces it with whatever the wallet reports.
      printV("MoneroFrozenCoinsStore: no coin index for $id, frozen flag cached only");
      _frozen[id] = frozen;
      return;
    }

    // Awaited rather than fired and forgotten. The index came from the last
    // walk, so a change still in flight while the coin list is refreshed can
    // be applied against a different ordering -- the mutex serialises the
    // calls but cannot tell that an index has gone stale between them.
    //
    // Awaiting also puts the cache update after the wallet has taken the
    // change, so a failure leaves the two agreeing rather than leaving the
    // cache claiming something wallet2 rejected, and reaches the caller
    // instead of only the log.
    await (frozen ? _freeze(index) : _thaw(index));

    _frozen[id] = frozen;
  }

  @override
  Future<void> deleteWallet(String walletId) async => beginRefresh();
}
