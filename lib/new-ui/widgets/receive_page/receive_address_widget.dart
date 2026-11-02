import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/hardware_wallet/proceed_on_device_message.dart';
import 'package:cake_wallet/utils/address_formatter.dart';
import 'package:cake_wallet/view_model/wallet_address_list/receive_address_data.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class ReceiveAddressWidget extends StatefulWidget {
  const ReceiveAddressWidget({
    super.key,
    required this.addressListViewModel,
    this.showVerifyAddressButton = false,
    this.isVerifyAddressBusy = false,
    this.onVerifyAddressPressed,
  });

  final ReceiveAddressData addressListViewModel;
  final bool showVerifyAddressButton;
  final bool isVerifyAddressBusy;
  final Future<void> Function()? onVerifyAddressPressed;

  @override
  State<ReceiveAddressWidget> createState() => _ReceiveAddressWidgetState();
}

class _ReceiveAddressWidgetState extends State<ReceiveAddressWidget> {
  bool _isBusy = false;

  bool get _effectiveBusy => widget.isVerifyAddressBusy || _isBusy;

  Future<void> _handlePressed() async {
    if (_effectiveBusy || widget.onVerifyAddressPressed == null) {
      return;
    }

    setState(() => _isBusy = true);
    try {
      await widget.onVerifyAddressPressed!();
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final shouldShowVerifyAddressButton =
        widget.showVerifyAddressButton && widget.onVerifyAddressPressed != null && !_effectiveBusy;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          key: const ValueKey("receive_page_address_key"),
          padding: const EdgeInsets.symmetric(horizontal: 50.0),
          child: Observer(
            builder: (_) => AddressFormatter.buildSegmentedAddress(
              address: widget.addressListViewModel.uri.address,
              walletType: widget.addressListViewModel.type,
              textAlign: TextAlign.center,
              evenTextStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
                fontFamily: "IBM Plex Mono",
              ),
            ),
          ),
        ),
        if (widget.showVerifyAddressButton)
          Padding(
            padding: const EdgeInsets.only(top: 18.0),
            child: _effectiveBusy
                ? HardwareWalletProceedOnDeviceMessage(
                    hardwareWalletType: HardwareWalletType.ledger,
                  )
                : shouldShowVerifyAddressButton
                ? FilledButton.icon(
                    onPressed: _handlePressed,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.verified_rounded),
                    label: Text(S.of(context).verify_address_on_device),
                  )
                : const SizedBox.shrink(),
          ),
      ],
    );
  }
}
