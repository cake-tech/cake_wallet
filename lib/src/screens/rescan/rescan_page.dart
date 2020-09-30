import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/view_model/rescan_view_model.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/blockchain_height_widget.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/generated/i18n.dart';

class RescanPage extends BasePage {
  RescanPage(this._rescanViewModel)
      : _blockchainHeightWidgetKey = GlobalKey<BlockchainHeightState>();

  @override
  String get title => S.current.rescan;
  final GlobalKey<BlockchainHeightState> _blockchainHeightWidgetKey;
  final RescanViewModel _rescanViewModel;

  @override
  Widget body(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 24, right: 24, bottom: 24),
      child:
          Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(
          children: <Widget>[
            BlockchainHeightWidget(key: _blockchainHeightWidgetKey),
            Padding(
              padding: EdgeInsets.only(left: 40, right: 40, top: 24),
              child: Text(
                S.of(context).restore_from_date_or_blockheight,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                    color: Theme.of(context).hintColor
                ),
              ),
            )
          ],
        ),
        Observer(
            builder: (_) => LoadingPrimaryButton(
                  isLoading:
                      _rescanViewModel.state == RescanWalletState.rescaning,
                  text: S.of(context).rescan,
                  onPressed: () async {
                    await _rescanViewModel.rescanCurrentWallet(
                        restoreHeight:
                            _blockchainHeightWidgetKey.currentState.height);
                    Navigator.of(context).pop();
                  },
                  color: Theme.of(context).accentTextTheme.body2.color,
                  textColor: Colors.white,
                ))
      ]),
    );
  }
}
