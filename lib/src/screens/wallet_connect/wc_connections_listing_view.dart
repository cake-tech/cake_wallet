import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/wallet_connect/services/walletkit_service.dart';
import 'package:cake_wallet/src/screens/wallet_connect/widgets/enter_wallet_connect_uri_widget.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/utils/device_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:reown_walletkit/reown_walletkit.dart';
import 'package:cake_wallet/entities/qr_scanner.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/utils/permission_handler.dart';

import 'widgets/wc_pairing_item_widget.dart';
import 'wc_pairing_detail_page.dart';

class WalletConnectConnectionsView extends StatelessWidget {
  final WalletKitService walletKitService;

  WalletConnectConnectionsView({required this.walletKitService, Uri? launchUri, Key? key})
      : super(key: key) {
    _triggerPairingFromDeeplink(launchUri);
  }

  void _triggerPairingFromDeeplink(Uri? launchUri) async {
    if (launchUri == null) return;

    final actualLinkList = launchUri.query.split("uri=");

    if (actualLinkList.length <= 1) return;

    final query = actualLinkList[1];

    final uri = Uri.decodeComponent(query);

    final uriData = Uri.parse(uri);

    await walletKitService.pairWithUri(uriData);
  }

  @override
  Widget build(BuildContext context) {
    return WCPairingsWidget(walletKitService: walletKitService);
  }
}

class WCPairingsWidget extends BasePage {
  WCPairingsWidget({required this.walletKitService, Key? key})
      : walletKit = walletKitService.walletKit;

  final ReownWalletKit walletKit;
  final WalletKitService walletKitService;

  @override
  String get title => S.current.walletConnect;

  Future<void> _onScanQrCode(BuildContext context, ReownWalletKit web3Wallet) async {
    final String? uri;

    if (DeviceInfo.instance.isMobile) {
      bool isCameraPermissionGranted =
          await PermissionHandler.checkPermission(Permission.camera, context);
      if (!isCameraPermissionGranted) return;
      uri = await presentQRScanner(context);
    } else {
      uri = await _showEnterWalletConnectURIPopUp(context);
    }

    await _handleWalletConnectURI(uri, context);
  }

  Future<String?> _showEnterWalletConnectURIPopUp(BuildContext context) async {
    final walletConnectURI = await showPopUp<String>(
      context: context,
      builder: (BuildContext context) {
        return EnterWalletConnectURIWrapperWidget();
      },
    );
    return walletConnectURI;
  }

  Future<void> _handleWalletConnectURI(
    String? walletConnectURI,
    BuildContext context,
  ) async {
    if (walletConnectURI == null) return _invalidUriToast(context, S.current.nullURIError);

    log('_onFoundUri: $walletConnectURI');
    final Uri uriData = Uri.parse(walletConnectURI);
    await walletKitService.pairWithUri(uriData);
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
    return Observer(
      builder: (context) {
        return Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  SizedBox(height: 24),
                  Text(
                    S.current.connectWalletPrompt,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 16.0,
                      fontWeight: FontWeight.normal,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 16),
                  PrimaryButton(
                    text: S.current.newConnection,
                    color: Theme.of(context).colorScheme.primary,
                    textColor: Theme.of(context).colorScheme.onPrimary,
                    onPressed: () => _onScanQrCode(context, walletKit),
                  ),
                  SizedBox(height: 4),
                  TextButton(
                    onPressed: () async {
                      final uri = await _showEnterWalletConnectURIPopUp(context);
                      await _handleWalletConnectURI(uri, context);
                    },
                    child: Text(
                      'Click to paste WalletConnect Link',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: Visibility(
                visible: walletKitService.pairings.isEmpty,
                child: Center(
                  child: Text(
                    S.current.activeConnectionsPrompt,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 16.0,
                      fontWeight: FontWeight.normal,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                replacement: ListView.builder(
                  itemCount: walletKitService.pairings.length,
                  itemBuilder: (BuildContext context, int index) {
                    final pairing = walletKitService.pairings[index];
                    return WCPairingItemWidget(
                      key: ValueKey(pairing.topic),
                      pairing: pairing,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WalletConnectPairingDetailsPage(
                              pairing: pairing,
                              walletKitService: walletKitService,
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
      },
    );
  }
}
