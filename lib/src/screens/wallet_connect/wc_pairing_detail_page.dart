import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/wallet_connect/services/walletkit_service.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:reown_walletkit/reown_walletkit.dart';

import 'utils/namespace_model_builder.dart';

class WalletConnectPairingDetailsPage extends StatefulWidget {
  final PairingInfo pairing;
  final WalletKitService walletKitService;

  const WalletConnectPairingDetailsPage({
    required this.pairing,
    required this.walletKitService,
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initSessions();
    });
  }

  void initDateTime() {
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(widget.pairing.expiry * 1000);
    int year = dateTime.year;
    int month = dateTime.month;
    int day = dateTime.day;

    expiryDate = '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
  }

  void initSessions() {
    List<SessionData> sessions = widget.walletKitService.getSessionsForPairingInfo(widget.pairing);

    for (final SessionData session in sessions) {
      List<Widget> namespaceWidget = ConnectionWidgetBuilder.buildFromNamespaces(
        session.topic,
        session.namespaces,
        context,
      );
      // Loop through and add the namespace widgets, but put 20 pixels between each one
      for (int i = 0; i < namespaceWidget.length; i++) {
        sessionWidgets.add(namespaceWidget[i]);
        if (i != namespaceWidget.length - 1) {
          sessionWidgets.add(const SizedBox(height: 20.0));
        }
      }

      sessionWidgets.add(const SizedBox.square(dimension: 10.0));
      sessionWidgets.add(
        PrimaryButton(
          onPressed: () async {
            try {
              await widget.walletKitService.extendSession(
                topic: session.topic,
              );
            } catch (e) {
              debugPrint('${e.toString()}');
            }
          },
          text: S.current.extend_session,
          color: Theme.of(context).colorScheme.primary,
          textColor: Theme.of(context).colorScheme.onPrimary,
        ),
      );
      sessionWidgets.add(const SizedBox.square(dimension: 10.0));
      sessionWidgets.add(
        PrimaryButton(
          onPressed: () async {
            try {
              await widget.walletKitService.updateSession(
                topic: session.topic,
                namespaces: session.namespaces,
              );
            } catch (e) {
              debugPrint('${e.toString()}');
            }
          },
          text: S.current.update_session,
          color: Theme.of(context).colorScheme.primary,
          textColor: Theme.of(context).colorScheme.onPrimary,
        ),
      );
      sessionWidgets.add(const SizedBox.square(dimension: 10.0));
      sessionWidgets.add(
        PrimaryButton(
          onPressed: () async {
            try {
              await widget.walletKitService.disconnectSession(
                topic: session.topic,
              );
            } catch (e) {
              debugPrint('${e.toString()}');
            }
          },
          text: S.current.disconnect_session,
          color: Theme.of(context).colorScheme.primary,
          textColor: Theme.of(context).colorScheme.onPrimary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WCCDetailsWidget(
      widget.pairing,
      expiryDate,
      sessionWidgets,
      widget.walletKitService,
    );
  }
}

class WCCDetailsWidget extends BasePage {
  WCCDetailsWidget(
    this.pairing,
    this.expiryDate,
    this.sessionWidgets,
    this.walletKitService,
  );

  final PairingInfo pairing;
  final String expiryDate;
  final List<Widget> sessionWidgets;
  final WalletKitService walletKitService;

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
                      : AssetImage(
                        CakeTor.instance.enabled
                        ? 'assets/images/tor_logo.svg'
                        : 'assets/images/app_logo.png')) as ImageProvider<Object>,
                ),
              ),
              const SizedBox(height: 20.0),
              Text(
                pairing.peerMetadata!.name,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16.0),
              Text(
                pairing.peerMetadata!.url,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8.0),
              Text(
                '${S.current.expiresOn}: $expiryDate',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                    _onDeleteButtonPressed(context, pairing.peerMetadata!.name, walletKitService),
                text: S.current.delete,
                color: Theme.of(context).colorScheme.primary,
                textColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onDeleteButtonPressed(
    BuildContext context,
    String dAppName,
    WalletKitService walletKitService,
  ) async {
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
        await walletKitService.deletePairing(topic: pairing.topic);

        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    }
  }
}
