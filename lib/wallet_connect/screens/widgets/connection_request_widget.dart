import 'package:flutter/material.dart';
import '../../utils/namespace_model_builder.dart';
import '../../models/auth_request_model.dart';
import '../../models/session_request_model.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';

import '../../utils/constants.dart';
import '../../utils/string_constants.dart';
import '../../models/connection_model.dart';
import 'connection_widget.dart';

class ConnectionRequestWidget extends StatelessWidget {
  const ConnectionRequestWidget({
    Key? key,
    required this.wallet,
    this.authRequest,
    this.sessionProposal,
  }) : super(key: key);

  final Web3Wallet wallet;
  final AuthRequestModel? authRequest;
  final SessionRequestModel? sessionProposal;

  @override
  Widget build(BuildContext context) {
    // Get the connection metadata
    final ConnectionMetadata? metadata =
        authRequest?.request.requester ?? sessionProposal?.request.proposer;

    if (metadata == null) {
      return const Text('ERROR');
    }

    return Container(
      decoration: BoxDecoration(
        color: StyleConstants.layerColor1,
        borderRadius: BorderRadius.circular(
          StyleConstants.linear8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTitle(metadata.metadata.name),
          const Text(
            StringConstants.wouldLikeToConnect,
            style: StyleConstants.subtitleText,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: StyleConstants.linear8),
          Text(
            metadata.metadata.url,
            style: StyleConstants.bodyText,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: StyleConstants.linear8),
          authRequest != null ? _buildAuthRequest() : _buildSessionProposal(context),
        ],
      ),
    );
  }

  Widget _buildTitle(String text) {
    return Text(
      text,
      style: StyleConstants.titleText,
      textAlign: TextAlign.center,
    );
  }

  Widget _buildAuthRequest() {
    final model = ConnectionModel(
      text: wallet.formatAuthMessage(
        iss: 'did:pkh:eip155:1:${authRequest!.iss}',
        cacaoPayload: CacaoRequestPayload.fromPayloadParams(
          authRequest!.request.payloadParams,
        ),
      ),
    );

    return ConnectionWidget(
      title: StringConstants.message,
      info: [model],
    );
  }

  Widget _buildSessionProposal(BuildContext context) {
    // Create the connection models using the required and optional namespaces provided by the proposal data
    // The key is the title and the list of values is the data
    final List<ConnectionWidget> views = ConnectionWidgetBuilder.buildFromRequiredNamespaces(
      sessionProposal!.request.requiredNamespaces,
    );

    return Column(
      children: views,
    );
  }
}
