import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/main.dart';
import 'package:cake_wallet/new-ui/widgets/keyboard_hide_overlay.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/view_model/rescan_view_model.dart';
import 'package:cake_wallet/src/widgets/blockchain_height_widget.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class RescanPage extends StatefulWidget {
  RescanPage(this._rescanViewModel);

  final RescanViewModel _rescanViewModel;

  @override
  State<RescanPage> createState() => _RescanPageState();
}

class _RescanPageState extends State<RescanPage> {
  final TextEditingController _heightController = TextEditingController();


  @override
  Widget build(BuildContext context) {
    Widget child;
    if (widget._rescanViewModel.wallet.type != WalletType.decred) {
      child = Padding(
        padding: EdgeInsets.only(left: 24, right: 24, bottom: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Observer(
              builder: (_) => SingleChildScrollView(
                controller: ModalScrollController.of(context),
                child: BlockchainHeightWidget(
                  // key: _blockchainHeightWidgetKey,
                  onHeightOrDateEntered: (value) => widget._rescanViewModel.isButtonEnabled = value,
                  isSilentPaymentsScan: widget._rescanViewModel.isSilentPaymentsScan,
                  isMwebScan: widget._rescanViewModel.isMwebScan,
                  doSingleScan: widget._rescanViewModel.doSingleScan,
                  hasDatePicker: !widget._rescanViewModel.isMwebScan,
                  // disable date picker for mweb for now
                  toggleSingleScan: () =>
                      widget._rescanViewModel.doSingleScan = !widget._rescanViewModel.doSingleScan,
                  walletType: widget._rescanViewModel.wallet.type,
                  heightController: _heightController,
                  bitcoinMempoolAPIEnabled: widget._rescanViewModel.isBitcoinMempoolAPIEnabled,
                ),
              ),
            ),
            Observer(
              builder: (_) => LoadingPrimaryButton(
                isLoading: widget._rescanViewModel.state == RescanWalletState.rescaning,
                text: S.of(context).rescan,
                onPressed: () async {
                  if (widget._rescanViewModel.isSilentPaymentsScan) {
                    return _toggleSilentPaymentsScanning(context);
                  }

                  widget._rescanViewModel
                      .rescanCurrentWallet(restoreHeight: int.parse(_heightController.text));

                  Navigator.of(context).pop();
                },
                color: Theme.of(context).colorScheme.primary,
                textColor: Theme.of(context).colorScheme.onPrimary,
                isDisabled: !widget._rescanViewModel.isButtonEnabled,
              ),
            )
          ],
        ),
      );
    } else {
      child = Center(
        child: Padding(
          padding: EdgeInsets.only(left: 24, right: 24, bottom: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Spacer(),
              Observer(
                builder: (_) => LoadingPrimaryButton(
                  isLoading: widget._rescanViewModel.state == RescanWalletState.rescaning,
                  text: S.of(context).rescan,
                  onPressed: () async {
                    await widget._rescanViewModel.rescanCurrentWallet(restoreHeight: 0);
                    Navigator.of(context).pop();
                  },
                  color: Theme.of(context).colorScheme.primary,
                  textColor: Theme.of(context).colorScheme.onPrimary,
                ),
              )
            ],
          ),
        ),
      );
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      // onTap: () => FocusScope.of(context).unfocus(),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        child: KeyboardHideOverlay(
          child: SafeArea(
            child: Column(
              children: [
                ModalTopBar(
                    title: widget._rescanViewModel.isSilentPaymentsScan
                        ? S.current.silent_payments_scanning
                        : S.current.rescan,
                    leadingIcon: Icon(Icons.arrow_back_ios_new),
                    onLeadingPressed: Navigator.of(context).pop),
                Expanded(
                    child: Padding(
                  padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                  child: child,
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _toggleSilentPaymentsScanning(BuildContext context) async {
    final height = int.parse(_heightController.text);

    Navigator.of(context).pop();

    final needsToSwitch =
        await bitcoin!.getNodeIsElectrsSPEnabled(widget._rescanViewModel.wallet) == false;

    if (needsToSwitch) {
      return showPopUp<void>(
        context: navigatorKey.currentState!.context,
        builder: (BuildContext _dialogContext) => AlertWithTwoActions(
          alertTitle: S.of(_dialogContext).change_current_node_title,
          alertContent: S.of(_dialogContext).confirm_silent_payments_switch_node,
          rightButtonText: S.of(_dialogContext).confirm,
          leftButtonText: S.of(_dialogContext).cancel,
          actionRightButton: () async {
            Navigator.of(_dialogContext).pop();

            widget._rescanViewModel.rescanCurrentWallet(restoreHeight: height);
          },
          actionLeftButton: () => Navigator.of(_dialogContext).pop(),
        ),
      );
    }

    widget._rescanViewModel.rescanCurrentWallet(restoreHeight: height);
  }
}
