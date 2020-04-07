import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:provider/provider.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/stores/wallet/wallet_store.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/domain/common/wallet_type.dart';
import 'package:cake_wallet/src/screens/receive/widgets/receive_with_subaddress.dart';
import 'package:cake_wallet/src/screens/receive/widgets/receive_without_subaddress.dart';

class ReceivePage extends BasePage {
  @override
  bool get isModalBackButton => true;

  @override
  String get title => S.current.receive;

  @override
  Widget trailing(BuildContext context) {
    return SizedBox(
      height: 37.0,
      width: 37.0,
      child: ButtonTheme(
        minWidth: double.minPositive,
        child: FlatButton(
            highlightColor: Colors.transparent,
            splashColor: Colors.transparent,
            padding: EdgeInsets.all(0),
            onPressed: () => Share.text(
                'Share address',
                _getSharedAddress(context),
                'text/plain'),
            child: Icon(
              Icons.share,
              size: 30.0,
            )),
      ),
    );
  }

  String _getSharedAddress(BuildContext context){
    final walletStore = Provider.of<WalletStore>(context);
    switch (walletStore.walletType) {
      case WalletType.monero:
        return walletStore.subaddress.address;
        break;
      case WalletType.bitcoin:
        return walletStore.address;
        break;
      case WalletType.none:
        return "";
    }
    return "";
  }

  @override
  Widget body(BuildContext context) => ReceiveBody();
}

class ReceiveBody extends StatefulWidget {
  @override
  ReceiveBodyState createState() => ReceiveBodyState();
}

class ReceiveBodyState extends State<ReceiveBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(afterLayout);
  }

  void afterLayout(dynamic _) {
    setAmountValue();
  }

  void setAmountValue() {
    final walletStore = Provider.of<WalletStore>(context);
    walletStore.onChangedAmountValue('');
  }

  @override
  Widget build(BuildContext context) {
    final walletStore = Provider.of<WalletStore>(context);
    return walletStore.walletType == WalletType.monero
    ? ReceiveWithSubaddress()
    : ReceiveWithoutSubaddress();
  }
}
