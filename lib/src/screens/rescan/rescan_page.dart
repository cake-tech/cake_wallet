import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/blockchain_height_widget.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/stores/rescan/rescan_wallet_store.dart';
import 'package:cake_wallet/generated/i18n.dart';

class RescanPage extends BasePage {
  final blockchainKey = GlobalKey<BlockchainHeightState>();
  @override
  String get title => S.current.rescan;

  @override
  Widget body(BuildContext context) {
    final rescanWalletStore = Provider.of<RescanWalletStore>(context);

    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, bottom: 20),
      child:
          Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        BlockchainHeightWidget(key: blockchainKey),
        Observer(
            builder: (_) => LoadingPrimaryButton(
                isLoading:
                    rescanWalletStore.state == RescanWalletState.rescaning,
                text: S.of(context).rescan,
                onPressed: () async {
                  await rescanWalletStore.rescanCurrentWallet(
                      restoreHeight: blockchainKey.currentState.height);
                  Navigator.of(context).pop();
                },
                color:
                    Theme.of(context).primaryTextTheme.button.backgroundColor,
                borderColor:
                    Theme.of(context).primaryTextTheme.button.decorationColor))
      ]),
    );
  }
}
