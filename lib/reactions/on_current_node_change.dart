import 'package:mobx/mobx.dart';
import 'package:cw_core/node.dart';
import 'package:cake_wallet/store/app_store.dart';

ReactionDisposer _onCurrentNodeChangeReaction;

void startOnCurrentNodeChangeReaction(AppStore appStore) {
  _onCurrentNodeChangeReaction?.reaction?.dispose();
  appStore.settingsStore.nodes.observe((change) async {
    try {
      await appStore.wallet.connectToNode(node: change.newValue);
    } catch (e) {
      print(e.toString());
    }
  });
}
