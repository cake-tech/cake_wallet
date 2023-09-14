import 'dart:developer';

import 'package:cake_wallet/core/wallet_connect/wallet_connect_service.dart';
import 'package:cake_wallet/core/wallet_connect/wc_bottom_sheet_service.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/wallet_connect/widgets/modals/bottom_sheet_listener.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/entities/qr_scanner.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';

import 'widgets/session_item_widget.dart';
import 'wc_pairing_detail_page.dart';

class WalletConnectConnectionsView extends StatefulWidget {
  final WalletConnectService walletConnectService;
  final BottomSheetService bottomSheetService;
  WalletConnectConnectionsView({
    required this.walletConnectService,
    required this.bottomSheetService,
    Key? key,
  }) : super(key: key);

  @override
  WalletConnectConnectionsViewState createState() => WalletConnectConnectionsViewState();
}

class WalletConnectConnectionsViewState extends State<WalletConnectConnectionsView> {


  @override
  Widget build(BuildContext context) {
    return WCPairingsWidget(
      bottomSheetService: widget.bottomSheetService,
      walletConnectService: widget.walletConnectService,
    );
  }
}

class WCPairingsWidget extends BasePage {
  WCPairingsWidget({
    required this.bottomSheetService,
    required this.walletConnectService,
    Key? key,
  });

  final BottomSheetService bottomSheetService;
  final WalletConnectService walletConnectService;

  @override
  String get title => 'WalletConnect';

  Future<void> _onScanQrCode(BuildContext context) async {
    final String? uri = await presentQRScanner();

    if (uri == null) return _invalidUriToast(context, 'URI is null');

    try {
      log('_onFoundUri: $uri');
      await walletConnectService.createPairing(uri);
    } catch (e) {
      await _invalidUriToast(context, e.toString());
    }
  }

  Future<void> _invalidUriToast(BuildContext context, String message) async {
    await showPopUp<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertWithOneAction(
          alertTitle: S.of(context).error,
          alertContent: message,
          buttonText: S.of(context).ok,
          buttonAction: Navigator.of(context).pop,
          alertBarrierDismissible: false,
        );
      },
    );
  }

  @override
  Widget body(BuildContext context) {
    return BottomSheetListener(
      bottomSheetService: bottomSheetService,
      child: Observer(builder: (context) {
        return Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  SizedBox(height: 24),
                  Text(
                    'Connect your wallet with WalletConnect to make transactions',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.normal,
                      color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
                    ),
                  ),
                  SizedBox(height: 16),
                  PrimaryButton(
                    text: 'New Connection',
                    color: Theme.of(context).primaryColor,
                    textColor: Colors.white,
                    onPressed: () => _onScanQrCode(context),
                  ),
                ],
              ),
            ),
            SizedBox(height: 48),
            Expanded(
              child: Visibility(
                visible: walletConnectService.sessions.isEmpty,
                child: Center(
                  child: Text(
                    'Active connections will appear here',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.normal,
                      color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
                    ),
                  ),
                ),
                replacement: ListView.builder(
                  itemCount: walletConnectService.sessions.length,
                  itemBuilder: (BuildContext context, int index) {
                    final session = walletConnectService.sessions[index];
                    return SessionItemWidget(
                      key: ValueKey(session.topic),
                      session: session,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WalletConnectPairingDetailsPage(
                              session: session,
                              walletConnectService: walletConnectService,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 48),
          ],
        );
      }
      ),
    );
  }
}
