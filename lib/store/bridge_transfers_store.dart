import 'package:cake_wallet/entities/bridge_transfer.dart';
import 'package:mobx/mobx.dart';

part 'bridge_transfers_store.g.dart';

class BridgeTransfersStore = BridgeTransfersStoreBase with _$BridgeTransfersStore;

abstract class BridgeTransfersStoreBase with Store {
  BridgeTransfersStoreBase() : bridgeTransfers = [] {
    updateList();
  }

  @observable
  List<BridgeTransfer> bridgeTransfers;

  @action
  Future<void> updateList() async {
    bridgeTransfers = await BridgeTransfer.selectAll();
  }

  @action
  Future<void> addTransfer(BridgeTransfer transfer) async {
    try {
      await BridgeTransfer.insert(transfer);
      await updateList();
    } catch (_) {}
  }

  @action
  Future<void> updateTransfer(BridgeTransfer transfer) async {
    try {
      await BridgeTransfer.update(transfer);
      await updateList();
    } catch (_) {}
  }

  @computed
  List<BridgeTransfer> get activeTransfers =>
      bridgeTransfers.where((b) => b.isActive).toList(growable: false);

  @computed
  List<BridgeTransfer> get pastTransfers =>
      bridgeTransfers.where((b) => !b.isActive).toList(growable: false);

  void dispose() {}
}
