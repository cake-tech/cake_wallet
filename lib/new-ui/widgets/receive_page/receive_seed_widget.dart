import 'package:cake_wallet/utils/address_formatter.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_list_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class ReceiveSeedWidget extends StatelessWidget {
  const ReceiveSeedWidget({super.key, required this.addressListViewModel});

  final WalletAddressListViewModel addressListViewModel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50.0),
      child: Observer(
        builder: (_) => AddressFormatter.buildSegmentedAddress(
          address: addressListViewModel.uri.address,
          walletType: addressListViewModel.type,
          textAlign: TextAlign.center,
          evenTextStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
            fontFamily: "IBM Plex Mono"
              ),
        ),
      ),
    );
  }
}
