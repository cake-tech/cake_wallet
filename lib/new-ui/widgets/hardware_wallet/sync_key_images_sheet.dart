import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/new-ui/widgets/send_page/directional_switcher.dart";
import "package:cake_wallet/routes.dart";
import "package:cake_wallet/src/screens/connect_device/connect_device_page.dart";
import "package:cake_wallet/src/widgets/alert_with_two_actions.dart";
import "package:cake_wallet/src/widgets/base_alert_dialog.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/src/widgets/primary_button.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cake_wallet/utils/show_pop_up.dart";
import "package:cake_wallet/view_model/hardware_wallet/trezor_connect_view_model.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_info.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";

class SyncKeyImagesSheet extends StatefulWidget {
  const SyncKeyImagesSheet({
    required this.appStore,
    required this.trezorConnectVM,
    super.key,
  });

  final AppStore appStore;
  final TrezorConnectViewModelBase trezorConnectVM;

  WalletBase get wallet => appStore.wallet!;

  @override
  State<SyncKeyImagesSheet> createState() => _HardwareWalletProceedOnDeviceSheetState();
}

class _HardwareWalletProceedOnDeviceSheetState extends State<SyncKeyImagesSheet> {
  _KeyImageSyncState _state = _KeyImageSyncState.initial;

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        child: SafeArea(
          bottom: false,
          child: Container(
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                child: Column(
                  children: [
                    ModalTopBar(
                      title: S.of(context).resync_device,
                      leadingIcon: Icon(
                        Icons.close,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      onLeadingPressed: () => showPopUp(
                        context: context,
                        builder: (context) => AlertWithTwoActions(
                          alertTitle: S.of(context).are_you_sure_exit,
                          alertContent: S.of(context).resync_device_cancel_warning_desc,
                          leftButtonText: S.of(context).cancel,
                          rightButtonText: S.of(context).yes_exit,
                          rightAlertButtonStyle: AlertButtonStyle.error(context),
                          actionLeftButton: Navigator.of(context).pop,
                          actionRightButton: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        spacing: 12,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CakeImageWidget(
                            imageUrl: hardwareWalletIcon,
                            width: 100,
                            colorFilter: ColorFilter.mode(
                              Theme.of(context).colorScheme.onSurfaceVariant,
                              BlendMode.srcIn,
                            ),
                          ),
                          DirectionalAnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            child: content,
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: AnimatedOpacity(
                        curve: Curves.easeOutQuad,
                        opacity: _state == _KeyImageSyncState.initial ? 1 : 0,
                        duration: const Duration(milliseconds: 300),
                        child: PrimaryButton(
                          text: S.of(context).continue_text,
                          color: Theme.of(context).colorScheme.primary,
                          textColor: Theme.of(context).colorScheme.onPrimary,
                          onPressed: _onContinuePressed,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  Widget get content {
    if (_state == _KeyImageSyncState.syncing) {
      return _syncingKeyImages();
    }

    return _initial();
  }

  String? get hardwareWalletIcon {
    switch (widget.wallet.hardwareWalletType) {
      case HardwareWalletType.bitbox:
        return "assets/new-ui/hardware_wallets/device_bitbox.svg";
      case HardwareWalletType.ledger:
        return "assets/new-ui/hardware_wallets/device_ledger_nano_x.svg";
      case HardwareWalletType.trezor:
        return "assets/new-ui/hardware_wallets/device_trezor_safe_7.svg";
      case HardwareWalletType.cupcake:
        return "assets/images/cupcake.svg";
      case HardwareWalletType.coldcard:
      case HardwareWalletType.seedsigner:
      case HardwareWalletType.keystone:
      case null:
        return "assets/images/hardware_wallet/device_qr.svg";
    }
  }

  Widget _initial() => Column(
        key: const ValueKey(0),
        spacing: 12,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              S.of(context).resync_device_desc,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      );

  Widget _syncingKeyImages() => Column(
    key: const ValueKey(1),
    spacing: 12,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        S.of(context).proceed_on_device,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 20,
        ),
      ),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          S.of(context).proceed_on_device_description,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      )
    ],
  );

  Future<void> _onContinuePressed() async {
    setState(() => _state = _KeyImageSyncState.syncing);

    if (!widget.trezorConnectVM.isConnected(widget.wallet.type)) {
      await Navigator.of(context).pushNamed(
        Routes.connectDevices,
        arguments: ConnectDevicePageParams(
          walletType: widget.wallet.type,
          hardwareWalletType: widget.wallet.walletInfo.hardwareWalletType!,
          onConnectDevice: (_, __) {
            widget.trezorConnectVM.initWallet(widget.wallet);
            Navigator.of(context).pop();
          },
          isReconnect: false,
        ),
      );

      // Recheck to handle tap-backs
      if (!widget.trezorConnectVM.isConnected(widget.wallet.type)) {
        setState(() => _state = _KeyImageSyncState.initial);
        return;
      }
    } else {
      await widget.trezorConnectVM.initWallet(widget.wallet);
    }

    final result = await widget.trezorConnectVM.syncKeyImages(widget.wallet);
    if (result && context.mounted) {
      Navigator.of(context).pop();
    }
  }
}

enum _KeyImageSyncState {
  initial,
  syncing;
}
