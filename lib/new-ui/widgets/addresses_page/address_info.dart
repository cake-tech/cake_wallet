import 'dart:ui';

import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_edit_or_create_view_model.dart';
import 'package:flutter/material.dart';

class AddressInfoPopup extends StatelessWidget {
  const AddressInfoPopup({
    super.key,
    required this.walletAddressEditOrCreateViewModel,
  });

  final WalletAddressEditOrCreateViewModel walletAddressEditOrCreateViewModel;

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
      child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadiusGeometry.lerp(
                  BorderRadius.circular(12),
                  BorderRadius.circular(24),
                  0.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Text('Index: ${walletAddressEditOrCreateViewModel.index}'),
                    SizedBox(height: 16),
                    Text('Derivation Path: ${walletAddressEditOrCreateViewModel.derivationPath}'),
                  ],
                ),
              ),
            ),
          ]),
    );
  }
}
