import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/wallet_connect/services/key_service/wallet_connect_key_service.dart';
import 'package:cake_wallet/src/screens/wallet_connect/models/wc_connection_model.dart';
import 'package:cake_wallet/src/screens/wallet_connect/utils/namespace_model_builder.dart';
import 'package:cake_wallet/src/screens/wallet_connect/widgets/wc_connection_widget.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:flutter/material.dart';
import 'package:reown_walletkit/reown_walletkit.dart';

class WCConnectionRequestWidget extends StatelessWidget {
  WCConnectionRequestWidget({
    this.sessionAuthPayload,
    this.proposalData,
    this.requester,
    this.verifyContext,
    required this.walletKeyService,
    required this.walletKit,
    required this.appStore,
  });

  final SessionAuthPayload? sessionAuthPayload;
  final ProposalData? proposalData;
  final ConnectionMetadata? requester;
  final VerifyContext? verifyContext;
  final WalletConnectKeyService walletKeyService;
  final AppStore appStore;
  final ReownWalletKit walletKit;

  @override
  Widget build(BuildContext context) {
    if (requester == null) {
      return Text(S.current.error.toUpperCase());
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Text(
            '${requester!.metadata.name} ${S.current.wouoldLikeToConnect}',
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          (sessionAuthPayload != null)
              ? _buildSessionAuthRequestView()
              : _buildSessionProposalView(context),
        ],
      ),
    );
  }

  Widget _buildSessionAuthRequestView() {
    final cacaoPayload = CacaoRequestPayload.fromSessionAuthPayload(
      sessionAuthPayload!,
    );

    final List<WCConnectionModel> messagesModels = [];
    for (var chain in sessionAuthPayload!.chains) {
      final chainKeys = walletKeyService.getKeysForChain(appStore.wallet!);
      final iss = 'did:pkh:$chain:${chainKeys.first.publicKey}';

      final message = walletKit.formatAuthMessage(
        iss: iss,
        cacaoPayload: cacaoPayload,
      );

      messagesModels.add(
        WCConnectionModel(
          title: '${S.current.message} ${messagesModels.length + 1}',
          elements: [message],
        ),
      );
    }

    return WCConnectionWidget(
      title: '${messagesModels.length} ${S.current.messages}',
      info: messagesModels,
    );
  }

  Widget _buildSessionProposalView(BuildContext context) {
    // Create the connection models using the required and optional namespaces provided by the proposal data

    final views = ConnectionWidgetBuilder.buildFromRequiredNamespaces(
      proposalData!.generatedNamespaces ?? {},
    );

    return Column(children: views);
  }
}

