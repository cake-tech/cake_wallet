import 'dart:developer';

import 'package:cake_wallet/core/wallet_connect/web3wallet_service.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:flutter/material.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';

import 'utils/namespace_model_builder.dart';

class WalletConnectPairingDetailsPage extends StatefulWidget {
  final PairingInfo pairing;
  final Web3WalletService web3walletService;

  const WalletConnectPairingDetailsPage({
    required this.pairing,
    required this.web3walletService,
    super.key,
  });

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
    List<SessionData> sessions = widget.web3walletService.getSessionsForPairingInfo(widget.pairing);

    for (final SessionData session in sessions) {
      List<Widget> namespaceWidget = ConnectionWidgetBuilder.buildFromNamespaces(
        session.topic,
        session.namespaces,
        widget.web3walletService.getWeb3Wallet(),
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
    return WCCDetailsWidget(
      widget.pairing,
      expiryDate,
      sessionWidgets,
      widget.web3walletService,
    );
  }
}

class WCCDetailsWidget extends BasePage {
  WCCDetailsWidget(
    this.pairing,
    this.expiryDate,
    this.sessionWidgets,
    this.web3walletService,
  );

  final PairingInfo pairing;
  final String expiryDate;
  final List<Widget> sessionWidgets;
  final Web3WalletService web3walletService;

  @override
  Widget body(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: CircleAvatar(
                  backgroundImage: (pairing.peerMetadata!.icons.isNotEmpty
                          ? NetworkImage(pairing.peerMetadata!.icons[0])
                          : const AssetImage('assets/images/default_icon.png'))
                      as ImageProvider<Object>,
                ),
              ),
              const SizedBox(height: 20.0),
              Text(
                pairing.peerMetadata!.name,
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
                ),
              ),
              const SizedBox(height: 16.0),
              Text(
                pairing.peerMetadata!.url,
                style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.normal,
                  color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                '${S.current.expiresOn}: $expiryDate',
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
                onPressed: () =>
                    _onDeleteButtonPressed(context, pairing.peerMetadata!.name, web3walletService),
                text: S.current.delete,
                color: Theme.of(context).primaryColor,
                textColor: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onDeleteButtonPressed(
      BuildContext context, String dAppName, Web3WalletService web3walletService) async {
    bool confirmed = false;

    await showPopUp<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertWithTwoActions(
          alertTitle: S.of(context).delete,
          alertContent: '${S.current.deleteConnectionConfirmationPrompt} $dAppName?',
          leftButtonText: S.of(context).cancel,
          rightButtonText: S.of(context).delete,
          actionLeftButton: () => Navigator.of(dialogContext).pop(),
          actionRightButton: () {
            confirmed = true;
            Navigator.of(dialogContext).pop();
          },
        );
      },
    );
    if (confirmed) {
      try {
        await web3walletService.disconnectSession(pairing.topic);

        Navigator.of(context).pop();
      } catch (e) {
        log(e.toString());
      }
    }
  }
}
