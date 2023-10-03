import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/wallet_connect/widgets/connection_widget.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';

import '../../../../core/wallet_connect/models/connection_model.dart';

class ConnectionWidgetBuilder {
  static List<ConnectionWidget> buildFromRequiredNamespaces(
    Map<String, RequiredNamespace> requiredNamespaces,
  ) {
    final List<ConnectionWidget> views = [];
    for (final key in requiredNamespaces.keys) {
      RequiredNamespace ns = requiredNamespaces[key]!;
      final List<ConnectionModel> models = [];
      // If the chains property is present, add the chain data to the models
      if (ns.chains != null) {
        models.add(ConnectionModel(title: S.current.chains, elements: ns.chains!));
      }
      models.add(ConnectionModel(title: S.current.methods, elements: ns.methods));
      models.add(ConnectionModel(title: S.current.events, elements: ns.events));

      views.add(ConnectionWidget(title: key, info: models));
    }

    return views;
  }

  static List<ConnectionWidget> buildFromNamespaces(
    String topic,
    Map<String, Namespace> namespaces,
    Web3Wallet web3wallet,
  ) {
    final List<ConnectionWidget> views = [];
    for (final key in namespaces.keys) {
      final Namespace ns = namespaces[key]!;
      final List<ConnectionModel> models = [];
      // If the chains property is present, add the chain data to the models
      models.add(
        ConnectionModel(
          title: S.current.chains,
          elements: ns.accounts,
        ),
      );
      models.add(ConnectionModel(
        title: S.current.methods,
        elements: ns.methods,
      ));

      Map<String, void Function()> actions = {};
      for (final String event in ns.events) {
        actions[event] = () async {
          final String chainId = NamespaceUtils.isValidChainId(key)
              ? key
              : NamespaceUtils.getChainFromAccount(ns.accounts.first);
          await web3wallet.emitSessionEvent(
            topic: topic,
            chainId: chainId,
            event: SessionEventParams(name: event, data: '${S.current.event}: $event'),
          );
        };
      }
      models.add(
        ConnectionModel(title: S.current.events, elements: ns.events, elementActions: actions),
      );

      views.add(ConnectionWidget(title: key, info: models));
    }

    return views;
  }
}
