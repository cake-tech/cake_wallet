import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/wallet_connect/widgets/connection_widget.dart';
import 'package:wallet_connect_v2/wallet_connect_v2.dart';

import '../../../../core/wallet_connect/models/connection_model.dart';

class ConnectionWidgetBuilder {
  static List<ConnectionWidget> buildFromSessionNamespaces(
    Map<String, SessionNamespace> sessionNamespaces,
  ) {
    final List<ConnectionWidget> views = [];

    for (final key in sessionNamespaces.keys) {
      SessionNamespace ns = sessionNamespaces[key]!;
      final List<ConnectionModel> models = [];
      // If the chains property is present, add the chain data to the models
      if (ns.chains != null) {
        models.add(
          ConnectionModel(
            title: S.current.chains,
            elements: ns.chains!,
          ),
        );
      }
      models.add(ConnectionModel(
        title: S.current.methods,
        elements: ns.methods,
      ));
      models.add(ConnectionModel(
        title: S.current.events,
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

  static List<ConnectionWidget> buildFromProposalNamespaces(
    Map<String, ProposalNamespace> proposalNamespaces,
  ) {
    final List<ConnectionWidget> views = [];

    for (final key in proposalNamespaces.keys) {
      ProposalNamespace ns = proposalNamespaces[key]!;
      final List<ConnectionModel> models = [];
      // If the chains property is present, add the chain data to the models
      if (ns.chains != null) {
        models.add(
          ConnectionModel(
            title: S.current.chains,
            elements: ns.chains!,
          ),
        );
      }
      models.add(ConnectionModel(
        title: S.current.methods,
        elements: ns.methods,
      ));
      models.add(ConnectionModel(
        title: S.current.events,
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
}
