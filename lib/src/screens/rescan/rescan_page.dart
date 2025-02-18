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
  String get title =>
      _rescanViewModel.isSilentPaymentsScan ? S.current.silent_payments_scanning : S.current.rescan;
  final GlobalKey<BlockchainHeightState> _blockchainHeightWidgetKey;
  final RescanViewModel _rescanViewModel;

  @override
  Widget body(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Padding(
        padding: EdgeInsets.only(left: 24, right: 24, bottom: 24),
        child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Observer(
              builder: (_) => BlockchainHeightWidget(
                    key: _blockchainHeightWidgetKey,
                    onHeightOrDateEntered: (value) => _rescanViewModel.isButtonEnabled = value,
                    isSilentPaymentsScan: _rescanViewModel.isSilentPaymentsScan,
                    isMwebScan: _rescanViewModel.isMwebScan,
                    doSingleScan: _rescanViewModel.doSingleScan,
                    hasDatePicker:
                        !_rescanViewModel.isMwebScan, // disable date picker for mweb for now
                    toggleSingleScan: () =>
                        _rescanViewModel.doSingleScan = !_rescanViewModel.doSingleScan,
                    walletType: _rescanViewModel.wallet.type,
                    bitcoinMempoolAPIEnabled: _rescanViewModel.isBitcoinMempoolAPIEnabled,
                  )),
          Observer(
              builder: (_) => LoadingPrimaryButton(
                    isLoading: _rescanViewModel.state == RescanWalletState.rescaning,
                    text: S.of(context).rescan,
                    onPressed: () async {
                      if (_rescanViewModel.isSilentPaymentsScan) {
                        return _rescanViewModel.toggleSilentPaymentsScanning(
                          context,
                          _blockchainHeightWidgetKey.currentState!.height,
                        );
                      }

                      _rescanViewModel.rescanCurrentWallet(
                          restoreHeight: _blockchainHeightWidgetKey.currentState!.height);

                      Navigator.of(context).pop();
                    },
                    color: Theme.of(context).primaryColor,
                    textColor: Colors.white,
                    isDisabled: !_rescanViewModel.isButtonEnabled,
                  ))
        ]),
      ),
    );
  }
}
