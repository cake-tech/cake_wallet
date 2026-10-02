import 'package:cw_core/utils/print_verbose.dart';
import "package:cw_core/wallet_type.dart";
import 'package:cake_wallet/store/app_store.dart';

final List<void Function()> _nodeObserverDisposers = [];

void startOnCurrentNodeChangeReaction(AppStore appStore) {
  for (final dispose in _nodeObserverDisposers) {
    dispose();
  }

  _nodeObserverDisposers.clear();

  final disposeNodes = appStore.settingsStore.nodes.observe((change) async {
    try {
      if (change.newValue?.type == appStore.wallet!.type) {
        await appStore.wallet!.connectToNode(node: change.newValue!);
      }
    } catch (e) {
      printV(e.toString());
    }
  });

  final disposeEvmChainNodes = appStore.settingsStore.evmChainNodes.observe((change) async {
    try {
      final wallet = appStore.wallet;
      final node = change.newValue;
      if (wallet == null || node == null) {
        return;
      }

      if (wallet.type == WalletType.evm && change.key == wallet.chainId) {
        await wallet.connectToNode(node: node);
      }
    } catch (e) {
      printV(e.toString());
    }
  });

  final disposePowNodes = appStore.settingsStore.powNodes.observe((change) async {
    try {
      if (change.newValue?.type == appStore.wallet!.type) {
        await appStore.wallet!.connectToPowNode(node: change.newValue!);
      }
    } catch (e) {
      printV(e.toString());
    }
  });

  _nodeObserverDisposers.addAll([disposeNodes, disposeEvmChainNodes, disposePowNodes]);
}
