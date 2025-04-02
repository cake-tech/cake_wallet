import 'package:cake_wallet/src/screens/wallet_connect/key_service/wallet_connect_key_service.dart';
import 'package:cake_wallet/src/screens/wallet_connect/models/connection_model.dart';
import 'package:cake_wallet/src/screens/wallet_connect/utils/namespace_model_builder.dart';
import 'package:cake_wallet/src/screens/wallet_connect/widgets/connection_widget.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:flutter/material.dart';
import 'package:reown_walletkit/reown_walletkit.dart';

class WCConnectionRequestWidget extends StatelessWidget {
  const WCConnectionRequestWidget({
    super.key,
    // this.authPayloadParams,
    this.sessionAuthPayload,
    this.proposalData,
    this.requester,
    this.verifyContext,
    required this.walletKeyService,
    required this.walletKit,
    required this.appStore,
  });

  // final AuthPayloadParams? authPayloadParams;
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
      return const Text('ERROR');
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
            '${requester!.metadata.name} would like to connect',
            style: TextStyle(
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
    //
    final cacaoPayload = CacaoRequestPayload.fromSessionAuthPayload(
      sessionAuthPayload!,
    );
    //
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
          title: 'Message ${messagesModels.length + 1}',
          elements: [
            message,
          ],
        ),
      );
    }
    //
    return WCConnectionWidget(
      title: '${messagesModels.length} Messages',
      info: messagesModels,
    );
  }

  Widget _buildSessionProposalView(BuildContext context) {
    // Create the connection models using the required and optional namespaces provided by the proposal data
    // The key is the title and the list of values is the data
    final views = ConnectionWidgetBuilder.buildFromRequiredNamespaces(
      proposalData!.generatedNamespaces!,
    );

    return Column(
      children: views,
    );
  }
}

class VerifyContextWidget extends StatelessWidget {
  const VerifyContextWidget({
    super.key,
    required this.verifyContext,
  });
  final VerifyContext? verifyContext;

  @override
  Widget build(BuildContext context) {
    if (verifyContext == null) {
      return const SizedBox.shrink();
    }

    if (verifyContext!.validation.scam) {
      return VerifyBanner(
        color: Colors.red,
        origin: verifyContext!.origin,
        title: 'Security risk',
        text: 'This domain is flagged as unsafe by multiple security providers.'
            ' Leave immediately to protect your assets.',
      );
    }
    if (verifyContext!.validation.invalid) {
      return VerifyBanner(
        color: Colors.red,
        origin: verifyContext!.origin,
        title: 'Domain mismatch',
        text: 'This website has a domain that does not match the sender of this request.'
            ' Approving may lead to loss of funds.',
      );
    }
    if (verifyContext!.validation.valid) {
      return VerifyHeader(
        iconColor: Colors.green,
        title: verifyContext!.origin,
      );
    }
    return VerifyBanner(
      color: Colors.orange,
      origin: verifyContext!.origin,
      title: 'Cannot verify',
      text: 'This domain cannot be verified. '
          'Check the request carefully before approving.',
    );
  }
}

class VerifyHeader extends StatelessWidget {
  const VerifyHeader({
    super.key,
    required this.iconColor,
    required this.title,
  });
  final Color iconColor;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.shield_outlined,
          color: iconColor,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: iconColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class VerifyBanner extends StatelessWidget {
  const VerifyBanner({
    super.key,
    required this.origin,
    required this.title,
    required this.text,
    required this.color,
  });
  final String origin, title, text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          origin,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox.square(dimension: 8.0),
        Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: const BorderRadius.all(Radius.circular(12.0)),
          ),
          child: Column(
            children: [
              VerifyHeader(
                iconColor: color,
                title: title,
              ),
              const SizedBox(height: 4.0),
              Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
