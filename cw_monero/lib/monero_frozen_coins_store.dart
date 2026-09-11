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
      printV("MoneroFrozenCoinsStore: no coin index for $id, frozen flag cached only");
      _frozen[id] = frozen;
      return;
    }

    await (frozen ? _freeze(index) : _thaw(index));

    _frozen[id] = frozen;
  }

  @override
  Future<void> deleteWallet(String walletId) async => beginRefresh();
}
