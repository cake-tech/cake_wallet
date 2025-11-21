import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_list_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../../src/screens/receive/widgets/qr_image.dart';

class ReceiveQrCode extends StatelessWidget {
  const ReceiveQrCode({
    super.key,
    required this.onTap,
    required this.largeQrMode,
    required this.addressListViewModel,
  });

  final VoidCallback onTap;
  final bool largeQrMode;
  final WalletAddressListViewModel addressListViewModel;

  static const double largeQrModeBottomPadding = 50;

  @override
  Widget build(BuildContext context) {
    final double targetY = largeQrMode ? 60 : 0;
    final double resolvedSize = MediaQuery.of(context).size.width * (largeQrMode ? 0.9 : 0.625);

    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: targetY),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, value),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                  width: resolvedSize,
                  height: resolvedSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white,
                  ),
                  padding: const EdgeInsets.all(8.0),
                  child: Observer(builder:(_)=> QrImage(data: addressListViewModel.uri.toString())),
                ),
                AnimatedSize(
                    duration: Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    child: SizedBox(height: largeQrMode ? largeQrModeBottomPadding : 0))
              ],
            ),
          );
        },
      ),
    );
  }
}
