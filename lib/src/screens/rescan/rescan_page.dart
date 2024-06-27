import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/view_model/rescan_view_model.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/blockchain_height_widget.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cw_core/wallet_type.dart';

class RescanPage extends BasePage {
  RescanPage(this._rescanViewModel, this.type)
      : _blockchainHeightWidgetKey = GlobalKey<BlockchainHeightState>();

  @override
  String get title => S.current.rescan;
  final GlobalKey<BlockchainHeightState> _blockchainHeightWidgetKey;
  final RescanViewModel _rescanViewModel;
  final WalletType type;

  @override
  Widget body(BuildContext context) {
    if (type == WalletType.decred) {
      return Padding(
        padding: EdgeInsets.only(left: 24, right: 24, bottom: 24),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Spacer(),
              Observer(
                  builder: (_) => LoadingPrimaryButton(
                        isLoading: _rescanViewModel.state ==
                            RescanWalletState.rescaning,
                        text: S.of(context).rescan,
                        onPressed: () async {
                          await _rescanViewModel.rescanCurrentWallet(
                              restoreHeight: 0);
                          Navigator.of(context).pop();
                        },
                        color: Theme.of(context).primaryColor,
                        textColor: Colors.white,
                      ))
            ]),
      );
    }
    return Padding(
      padding: EdgeInsets.only(left: 24, right: 24, bottom: 24),
      child:
          Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              BlockchainHeightWidget(key: _blockchainHeightWidgetKey,
                  type: this.type,
                  onHeightOrDateEntered: (value) =>
                  _rescanViewModel.isButtonEnabled = value),
        Observer(
            builder: (_) => LoadingPrimaryButton(
                  isLoading:
                      _rescanViewModel.state == RescanWalletState.rescaning,
                  text: S.of(context).rescan,
                  onPressed: () async {
                    await _rescanViewModel.rescanCurrentWallet(
                        restoreHeight:
                            _blockchainHeightWidgetKey.currentState!.height);
                    Navigator.of(context).pop();
                  },
                  color: Theme.of(context).primaryColor,
                  textColor: Colors.white,
                  isDisabled: !_rescanViewModel.isButtonEnabled,
                ))
      ]),
    );
  }
}
