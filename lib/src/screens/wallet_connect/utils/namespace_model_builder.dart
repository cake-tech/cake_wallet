import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/wallet_connect/models/wc_connection_model.dart';
import 'package:cake_wallet/src/screens/wallet_connect/widgets/wc_connection_widget.dart';
import 'package:flutter/material.dart';
import 'package:reown_walletkit/reown_walletkit.dart';

class ConnectionWidgetBuilder {
  static List<WCConnectionWidget> buildFromRequiredNamespaces(
    Map<String, Namespace> generatedNamespaces,
  ) {
    final List<WCConnectionWidget> views = [];
    for (final key in generatedNamespaces.keys) {
      final namespaces = generatedNamespaces[key]!;
      final chains = NamespaceUtils.getChainsFromAccounts(namespaces.accounts);

      final List<WCConnectionModel> models = [];

      // If the chains property is present, add the chain data to the models
      models.add(WCConnectionModel(title: S.current.chains, elements: chains));
      models.add(WCConnectionModel(title: S.current.methods, elements: namespaces.methods));

      if (namespaces.events.isNotEmpty) {
        models.add(WCConnectionModel(title: S.current.events, elements: namespaces.events));
      }

      views.add(WCConnectionWidget(title: key, info: models));
    }

    return views;
  }

  static List<WCConnectionWidget> buildFromNamespaces(
    String topic,
    Map<String, Namespace> namespaces,
    BuildContext context,
  ) {
    final List<WCConnectionWidget> views = [];
    for (final key in namespaces.keys) {
      final ns = namespaces[key]!;
      final List<WCConnectionModel> models = [];

      // If the chains property is present, add the chain data to the models
      models.add(WCConnectionModel(title: S.current.accounts, elements: ns.accounts));
      models.add(WCConnectionModel(title: S.current.methods, elements: ns.methods));

      if (ns.events.isNotEmpty) {
        models.add(WCConnectionModel(title: S.current.events, elements: ns.events));
      }

      views.add(WCConnectionWidget(title: key, info: models));
    }

    return views;
  }

  static Map<String, Namespace> updateNamespaces(
    Map<String, Namespace> currentNamespaces,
    String namespace,
    List<String> newChains,
  ) {
    final updatedNamespaces = Map<String, Namespace>.from(currentNamespaces);

    final accounts = currentNamespaces[namespace]!.accounts;
    final address = NamespaceUtils.getAccount(accounts.first);
    final newAccounts = newChains.map((c) => '$c:$address').toList();

    final newNamespaces = currentNamespaces[namespace]!.copyWith(
      chains: NamespaceUtils.getChainsFromAccounts(accounts)..addAll(newChains),
      accounts: List<String>.from(accounts)..addAll(newAccounts),
    );

    updatedNamespaces[namespace] = newNamespaces;

    return updatedNamespaces;
  }
}
