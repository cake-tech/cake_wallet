import 'dart:developer';
import 'package:cake_wallet/core/wallet_connect/web3wallet_service.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:cake_wallet/entities/qr_scanner.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';

import 'widgets/pairing_item_widget.dart';
import 'wc_pairing_detail_page.dart';

class WalletConnectConnectionsView extends StatelessWidget {
  final Web3WalletService web3walletService;

  WalletConnectConnectionsView({required this.web3walletService, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WCPairingsWidget(web3walletService: web3walletService);
  }
}

class WCPairingsWidget extends BasePage {
  WCPairingsWidget({required this.web3walletService, Key? key})
      : web3wallet = web3walletService.getWeb3Wallet();

  final Web3Wallet web3wallet;
  final Web3WalletService web3walletService;

  @override
  String get title => S.current.walletConnect;

  Future<void> _onScanQrCode(BuildContext context, Web3Wallet web3Wallet) async {
    final String? uri = await presentQRScanner();

    if (uri == null) return _invalidUriToast(context, S.current.nullURIError);

    try {
      log('_onFoundUri: $uri');
      final Uri uriData = Uri.parse(uri);
      await web3Wallet.pair(uri: uriData);
    } on WalletConnectError catch (e) {
      await _invalidUriToast(context, e.message);
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
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.normal,
                      color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
                    ),
                  ),
                  SizedBox(height: 16),
                  PrimaryButton(
                    text: S.current.newConnection,
                    color: Theme.of(context).primaryColor,
                    textColor: Colors.white,
                    onPressed: () => _onScanQrCode(context, web3wallet),
                  ),
                ],
              ),
            ),
            SizedBox(height: 48),
            Expanded(
              child: Visibility(
                visible: web3walletService.pairings.isEmpty,
                child: Center(
                  child: Text(
                    S.current.activeConnectionsPrompt,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.normal,
                      color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
                    ),
                  ),
                ),
                replacement: ListView.builder(
                  itemCount: web3walletService.pairings.length,
                  itemBuilder: (BuildContext context, int index) {
                    final pairing = web3walletService.pairings[index];
                    return PairingItemWidget(
                      key: ValueKey(pairing.topic),
                      pairing: pairing,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WalletConnectPairingDetailsPage(
                              pairing: pairing,
                              web3walletService: web3walletService,
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
