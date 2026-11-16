import "dart:async";

import "package:cake_wallet/entities/wallet_group_db_entry.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";

/// The only place that decides what name the UI shows for a wallet.
class WalletDisplayNames {
  Map<String, String> _groupNames = const {};
  Map<String, int> _groupSizes = const {};

  final _changes = StreamController<void>.broadcast();

  Stream<void> get changes => _changes.stream;

  Future<void> refresh() async {
    final groups = await WalletGroupDbEntry.getAll();
    final sizes = <String, int>{};
    for (final w in await WalletInfo.getAll()) {
      final id = w.groupId;
      if (id != null) {
        sizes[id] = (sizes[id] ?? 0) + 1;
      }
    }

    _groupNames = {for (final g in groups) g.id: (g.name ?? "").trim()};
    _groupSizes = sizes;
    _changes.add(null);
  }

  String groupName(WalletInfo w) {
    final name = _groupNames[w.groupId] ?? "";
    return name.isNotEmpty ? name : w.name;
  }

  String inGroup(WalletInfo w) => walletTypeToDisplayName(w.type);

  String inFlatList(WalletInfo w) =>
      (_groupSizes[w.groupId] ?? 1) > 1 ? "${groupName(w)} · ${inGroup(w)}" : groupName(w);
}
