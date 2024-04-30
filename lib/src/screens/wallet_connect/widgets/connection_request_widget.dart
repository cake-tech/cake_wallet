// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:cake_wallet/generated/i18n.dart';
import 'package:flutter/material.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';

import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';

import '../../../../core/wallet_connect/models/auth_request_model.dart';
import '../../../../core/wallet_connect/models/connection_model.dart';
import '../../../../core/wallet_connect/models/session_request_model.dart';
import '../utils/namespace_model_builder.dart';
import 'connection_widget.dart';

class ConnectionRequestWidget extends StatefulWidget {
  const ConnectionRequestWidget({
    required this.wallet,
    required this.chaindIdNamespace,
    this.authRequest,
    this.sessionProposal,
    Key? key,
  }) : super(key: key);

  final Web3Wallet wallet;
  final String chaindIdNamespace;
  final AuthRequestModel? authRequest;
  final SessionRequestModel? sessionProposal;

  @override
  State<ConnectionRequestWidget> createState() => _ConnectionRequestWidgetState();
}

class _ConnectionRequestWidgetState extends State<ConnectionRequestWidget> {
  ConnectionMetadata? metadata;

  @override
  void initState() {
    super.initState();
    // Get the connection metadata
    metadata = widget.authRequest?.request.requester ?? widget.sessionProposal?.request.proposer;
  }

  @override
  Widget build(BuildContext context) {
    if (metadata == null) {
      return Text(
        S.current.error,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: Theme.of(context).extension<CakeTextTheme>()!.secondaryTextColor,
        ),
      );
    }

    return _ConnectionMetadataDisplayWidget(
      metadata: metadata,
      wallet: widget.wallet,
      authRequest: widget.authRequest,
      sessionProposal: widget.sessionProposal,
      chaindIdNamespace: widget.chaindIdNamespace,
    );
  }
}

class _ConnectionMetadataDisplayWidget extends StatelessWidget {
  const _ConnectionMetadataDisplayWidget({
    required this.wallet,
    required this.metadata,
    required this.sessionProposal,
    required this.chaindIdNamespace,
    this.authRequest,
  });

  final ConnectionMetadata? metadata;
  final Web3Wallet wallet;
  final String chaindIdNamespace;
  final AuthRequestModel? authRequest;
  final SessionRequestModel? sessionProposal;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 18, 18, 19),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            metadata!.metadata.name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              color: Theme.of(context).extension<CakeTextTheme>()!.secondaryTextColor,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            S.current.wouoldLikeToConnect,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.normal,
              color: Theme.of(context).extension<CakeTextTheme>()!.secondaryTextColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            metadata!.metadata.url,
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.normal,
              color: Theme.of(context).extension<CakeTextTheme>()!.secondaryTextColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Visibility(
            visible: authRequest != null,
            child: _AuthRequestWidget(
              wallet: wallet,
              authRequest: authRequest,
              chaindIdNamespace: chaindIdNamespace,
            ),

            //If authRequest is null, sessionProposal is not null.
            replacement: _SessionProposalWidget(sessionProposal: sessionProposal!),
          ),
        ],
      ),
    );
  }
}

class _AuthRequestWidget extends StatelessWidget {
  const _AuthRequestWidget({
    required this.wallet,
    required this.chaindIdNamespace,
    this.authRequest,
  });

  final Web3Wallet wallet;
  final String chaindIdNamespace;
  final AuthRequestModel? authRequest;

  @override
  Widget build(BuildContext context) {
    final model = ConnectionModel(
      text: wallet.formatAuthMessage(
        iss: 'did:pkh:$chaindIdNamespace:${authRequest!.iss}',
        cacaoPayload: CacaoRequestPayload.fromPayloadParams(
          authRequest!.request.payloadParams,
        ),
      ),
    );
    return ConnectionWidget(
      title: S.current.message,
      info: [model],
    );
  }
}

class _SessionProposalWidget extends StatelessWidget {
  const _SessionProposalWidget({required this.sessionProposal});

  final SessionRequestModel sessionProposal;

  @override
  Widget build(BuildContext context) {
    // Create the connection models using the required and optional namespaces provided by the proposal data
    // The key is the title and the list of values is the data
    final List<ConnectionWidget> views = ConnectionWidgetBuilder.buildFromRequiredNamespaces(
      sessionProposal.request.requiredNamespaces,
    );

    return Column(children: views);
  }
}
