import 'package:cake_wallet/generated/i18n.dart';
import 'package:flutter/material.dart';
import 'package:wallet_connect_v2/wallet_connect_v2.dart';

import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';

import '../../../../core/wallet_connect/models/session_request_model.dart';
import '../utils/namespace_model_builder.dart';
import 'connection_widget.dart';

class ConnectionRequestWidget extends StatefulWidget {
  const ConnectionRequestWidget({
    this.sessionProposal,
    Key? key,
  }) : super(key: key);

  final SessionRequestModel? sessionProposal;

  @override
  State<ConnectionRequestWidget> createState() => _ConnectionRequestWidgetState();
}

class _ConnectionRequestWidgetState extends State<ConnectionRequestWidget> {
  AppMetadata? metadata;

  @override
  void initState() {
    super.initState();
    metadata = widget.sessionProposal?.request?.proposer;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.sessionProposal?.message != null) {
      return Column(
        children: [
          Text(
            S.current.sessionRequest,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              color: Theme.of(context).extension<CakeTextTheme>()!.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.sessionProposal?.message ?? '',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              color: Theme.of(context).extension<CakeTextTheme>()!.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 16),
        ],
      );
    }

    if (metadata == null) {
      return Text(
        S.current.error,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: Theme.of(context).extension<CakeTextTheme>()!.secondaryTextColor,
        ),
      );
    }

    return _ConnectionMetadataDisplayWidget(
      metadata: metadata,
      sessionProposal: widget.sessionProposal,
    );
  }


}

class _ConnectionMetadataDisplayWidget extends StatelessWidget {
  const _ConnectionMetadataDisplayWidget({
    required this.metadata,
    this.sessionProposal,
  });

  final AppMetadata? metadata;

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
            '${metadata!.name} ${S.current.wouldLikeToConnect}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              color: Theme.of(context).extension<CakeTextTheme>()!.secondaryTextColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            metadata!.url,
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.normal,
              color: Theme.of(context).extension<CakeTextTheme>()!.secondaryTextColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          _SessionProposalWidget(sessionProposal: sessionProposal),
        ],
      ),
    );
  }
}

class _SessionProposalWidget extends StatelessWidget {
  const _SessionProposalWidget({this.sessionProposal});

  final SessionRequestModel? sessionProposal;

  @override
  Widget build(BuildContext context) {
    // Create the connection models using the required and optional namespaces provided by the proposal data
    // The key is the title and the list of values is the data
    final List<ConnectionWidget> views = ConnectionWidgetBuilder.buildFromProposalNamespaces(
      sessionProposal!.request!.namespaces,
    );

    return Column(children: views);
  }
}
