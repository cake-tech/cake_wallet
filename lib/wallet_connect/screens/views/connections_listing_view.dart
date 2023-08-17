import 'dart:developer';

import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/qr_scanner.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/wallet_connect/screens/widgets/modals/bottom_sheet_listener.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:get_it_mixin/get_it_mixin.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';

import '../../services/web3wallet_service.dart';
import '../../utils/constants.dart';
import '../../utils/string_constants.dart';
import '../widgets/modals/uri_input_popup.dart';
import '../widgets/pairing_item_widget.dart';
import 'pairing_detail_page.dart';

class WalletConnectConnectionsView extends StatefulWidget with GetItStatefulWidgetMixin {
  WalletConnectConnectionsView({
    Key? key,
  }) : super(key: key);

  @override
  WalletConnectConnectionsViewState createState() => WalletConnectConnectionsViewState();
}

class WalletConnectConnectionsViewState extends State<WalletConnectConnectionsView>
    with GetItStateMixin {
  List<PairingInfo> _pairings = [];

  final Web3Wallet web3Wallet = getIt.get<Web3WalletService>().getWeb3Wallet();

  @override
  void initState() {
    _pairings = web3Wallet.pairings.getAll();
    // web3wallet.onSessionDelete.subscribe(_onSessionDelete);
    web3Wallet.core.pairing.onPairingDelete.subscribe(_onPairingDelete);
    web3Wallet.core.pairing.onPairingExpire.subscribe(_onPairingDelete);
    super.initState();
  }

  @override
  void dispose() {
    // web3wallet.onSessionDelete.unsubscribe(_onSessionDelete);
    web3Wallet.core.pairing.onPairingDelete.unsubscribe(_onPairingDelete);
    web3Wallet.core.pairing.onPairingExpire.unsubscribe(_onPairingDelete);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _pairings = watch(
      target: GetIt.I<Web3WalletService>().pairings,
    );

    return Scaffold(
      body: BottomSheetListener(
        child: Stack(
          children: [
            _pairings.isEmpty ? _buildNoPairingMessage() : _buildPairingList(),
            Positioned(
              bottom: StyleConstants.magic20,
              right: StyleConstants.magic20,
              child: Row(
                children: [
                  _buildIconButton(
                    Icons.cloud_off,
                    _onDisconnect,
                  ),
                  const SizedBox(
                    width: StyleConstants.magic20,
                  ),
                  _buildIconButton(
                    Icons.cloud_outlined,
                    _onConnect,
                  ),
                  const SizedBox(
                    width: StyleConstants.magic20,
                  ),
                  _buildIconButton(
                    Icons.copy,
                    _onCopyQrCode,
                  ),
                  const SizedBox(
                    width: StyleConstants.magic20,
                  ),
                  _buildIconButton(
                    Icons.qr_code_scanner,
                    _onScanQrCode,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoPairingMessage() {
    return const Center(
      child: Text(
        StringConstants.noApps,
        textAlign: TextAlign.center,
        style: StyleConstants.bodyText,
      ),
    );
  }

  Widget _buildPairingList() {
    final List<PairingItemWidget> pairingItems = _pairings
        .map(
          (PairingInfo pairing) => PairingItemWidget(
            key: ValueKey(pairing.topic),
            pairing: pairing,
            onTap: () => _onListItemTap(pairing),
          ),
        )
        .toList();

    return ListView.builder(
      itemCount: pairingItems.length,
      itemBuilder: (BuildContext context, int index) {
        return pairingItems[index];
      },
    );
  }

  Widget _buildIconButton(IconData icon, void Function()? onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: StyleConstants.primaryColor,
        borderRadius: BorderRadius.circular(
          StyleConstants.linear48,
        ),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: StyleConstants.titleTextColor,
        ),
        iconSize: StyleConstants.linear24,
        onPressed: onPressed,
      ),
    );
  }

  Future<void> _onDisconnect() async {
    log('disconnecting');
    await web3Wallet.core.relayClient.disconnect();
    log('disconnected');
  }

  Future<void> _onConnect() async {
    log("connecting");
    await web3Wallet.core.relayClient.connect();
    log("connected");
  }

  Future _onCopyQrCode() async {
    final String? uri = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return UriInputPopup();
      },
    );

    _onFoundUri(uri);
  }

  Future _onScanQrCode() async {
    final String? s = await presentQRScanner();

    _onFoundUri(s);
  }

  Future _onFoundUri(String? uri) async {
    if (uri != null) {
      try {
        log('_onFoundUri: $uri');
        final Uri uriData = Uri.parse(uri);
        await web3Wallet.pair(
          uri: uriData,
        );
      } catch (e) {
        _invalidUriToast();
      }
    } else {
      _invalidUriToast();
    }
  }

  void _invalidUriToast() {
    showPopUp(
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(StyleConstants.linear8),
          margin: const EdgeInsets.only(
            bottom: StyleConstants.magic40,
          ),
          decoration: BoxDecoration(
            color: StyleConstants.errorColor,
            borderRadius: BorderRadius.circular(
              StyleConstants.linear16,
            ),
          ),
          child: const Text(
            StringConstants.invalidUri,
            style: StyleConstants.bodyTextBold,
          ),
        );
      },
      context: context,
    );
  }

  void _onPairingDelete(PairingEvent? event) {
    setState(() {
      _pairings = web3Wallet.pairings.getAll();
    });
  }

  void _onListItemTap(PairingInfo pairing) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PairingDetailPage(
          pairing: pairing,
        ),
      ),
    );
  }
}
