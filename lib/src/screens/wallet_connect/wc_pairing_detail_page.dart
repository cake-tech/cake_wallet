import 'dart:developer';

import 'package:cake_wallet/core/wallet_connect/web3wallet_service.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:flutter/material.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';

import 'utils/namespace_model_builder.dart';

class WalletConnectPairingDetailsPage extends StatefulWidget {
  final PairingInfo pairing;

  const WalletConnectPairingDetailsPage({required this.pairing, super.key});

  @override
  WalletConnectPairingDetailsPageState createState() => WalletConnectPairingDetailsPageState();
}

class WalletConnectPairingDetailsPageState extends State<WalletConnectPairingDetailsPage> {
  List<Widget> sessionWidgets = [];
  late String expiryDate;
  @override
  void initState() {
    super.initState();
    initDateTime();
    initSessions();
  }

  void initDateTime() {
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(widget.pairing.expiry * 1000);
    int year = dateTime.year;
    int month = dateTime.month;
    int day = dateTime.day;

    expiryDate = '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
  }

  void initSessions() {
    List<SessionData> sessions = getIt
        .get<Web3WalletService>()
        .getWeb3Wallet()
        .sessions
        .getAll()
        .where((element) => element.pairingTopic == widget.pairing.topic)
        .toList();

    for (final SessionData session in sessions) {
      List<Widget> namespaceWidget = ConnectionWidgetBuilder.buildFromNamespaces(
        session.topic,
        session.namespaces,
      );
      // Loop through and add the namespace widgets, but put 20 pixels between each one
      for (int i = 0; i < namespaceWidget.length; i++) {
        sessionWidgets.add(namespaceWidget[i]);
        if (i != namespaceWidget.length - 1) {
          sessionWidgets.add(const SizedBox(height: 20.0));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pairing.peerMetadata?.name ?? 'Unknown'),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: CircleAvatar(
                  backgroundImage: (widget.pairing.peerMetadata!.icons.isNotEmpty
                          ? NetworkImage(widget.pairing.peerMetadata!.icons[0])
                          : const AssetImage('assets/images/default_icon.png'))
                      as ImageProvider<Object>,
                ),
              ),
              const SizedBox(height: 20.0),
              Text(
                widget.pairing.peerMetadata!.name,
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
                ),
              ),
              const SizedBox(height: 20.0),
              Text(
                widget.pairing.peerMetadata!.url,
                style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.normal,
                  color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
                ),
              ),
              Text(
                'Expires on: $expiryDate',
                style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.normal,
                  color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
                ),
              ),
              const SizedBox(height: 20.0),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: sessionWidgets,
              ),
              const SizedBox(height: 20.0),
              PrimaryButton(
                onPressed: _onDeleteButtonPressed,
                text: 'Delete',
                color: Theme.of(context).primaryColor,
                textColor: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _back() {
    Navigator.of(context).pop();
  }

  Future<void> _onDeleteButtonPressed() async {
    try {
      await getIt
          .get<Web3WalletService>()
          .getWeb3Wallet()
          .core
          .pairing
          .disconnect(topic: widget.pairing.topic);
      _back();
    } catch (e) {
      log(e.toString());
    }
  }
}
