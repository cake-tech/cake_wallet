import 'package:cake_wallet/entities/bridge_transfer.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/store/bridge_transfers_store.dart';
import 'package:mobx/mobx.dart';

part 'bridge_history_view_model.g.dart';

class BridgeHistoryViewModel = BridgeHistoryViewModelBase with _$BridgeHistoryViewModel;

abstract class BridgeHistoryViewModelBase with Store {
  BridgeHistoryViewModelBase({
    required this.bridgeTransfersStore,
    required this.appStore,
  });

  final BridgeTransfersStore bridgeTransfersStore;
  final AppStore appStore;

  @computed
  List<BridgeTransfer> get walletTransfers {
    final wallet = appStore.wallet;
    if (wallet == null) return [];

    return bridgeTransfersStore.bridgeTransfers.where((t) => t.walletId == wallet.name).toList();
  }

  @computed
  List<BridgeTransfer> get activeTransfers =>
      walletTransfers.where((b) => b.isActive).toList(growable: false);

  @computed
  List<BridgeTransfer> get pastTransfers =>
      walletTransfers.where((b) => !b.isActive).toList(growable: false);

  @computed
  bool get isEmpty => walletTransfers.isEmpty;
}
