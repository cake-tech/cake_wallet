import 'package:mobx/mobx.dart';
import 'package:cake_wallet/entities/node.dart';
import 'package:cake_wallet/store/app_store.dart';

ReactionDisposer _onCurrentNodeChangeReaction;

void startOnCurrentNodeChangeReaction(AppStore appStore) {
  _onCurrentNodeChangeReaction?.reaction?.dispose();
  _onCurrentNodeChangeReaction =
      reaction((_) => appStore.settingsStore.currentNode, (Node node) async {
    try {
      await appStore.wallet.connectToNode(node: node);
    } catch (e) {
      print(e.toString());
    }
  });
}
