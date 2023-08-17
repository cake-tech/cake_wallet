import 'package:cake_wallet/wallet_connect/screens/widgets/connection_widget.dart';
import 'package:cake_wallet/wallet_connect/utils/string_constants.dart';
import 'package:get_it/get_it.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';

import '../models/connection_model.dart';
import '../services/web3wallet_service.dart';

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
        models.add(
          ConnectionModel(
            title: StringConstants.chains,
            elements: ns.chains!,
          ),
        );
      }
      models.add(ConnectionModel(
        title: StringConstants.methods,
        elements: ns.methods,
      ));
      models.add(ConnectionModel(
        title: StringConstants.events,
        elements: ns.events,
      ));

      views.add(
        ConnectionWidget(
          title: key,
          info: models,
        ),
      );
    }

    return views;
  }

  static List<ConnectionWidget> buildFromNamespaces(
    String topic,
    Map<String, Namespace> namespaces,
  ) {
    final List<ConnectionWidget> views = [];
    for (final key in namespaces.keys) {
      final Namespace ns = namespaces[key]!;
      final List<ConnectionModel> models = [];
      // If the chains property is present, add the chain data to the models
      models.add(
        ConnectionModel(
          title: StringConstants.chains,
          elements: ns.accounts,
        ),
      );
      models.add(ConnectionModel(
        title: StringConstants.methods,
        elements: ns.methods,
      ));

      Map<String, void Function()> actions = {};
      for (final String event in ns.events) {
        actions[event] = () async {
          final String chainId = NamespaceUtils.isValidChainId(key)
              ? key
              : NamespaceUtils.getChainFromAccount(ns.accounts.first);
          await GetIt.I<Web3WalletService>().getWeb3Wallet().emitSessionEvent(
                topic: topic,
                chainId: chainId,
                event: SessionEventParams(
                  name: event,
                  data: 'Event: $event',
                ),
              );
        };
      }
      models.add(ConnectionModel(
        title: StringConstants.events,
        elements: ns.events,
        elementActions: actions,
      ));

      views.add(
        ConnectionWidget(
          title: key,
          info: models,
        ),
      );
    }

    return views;
  }
}
