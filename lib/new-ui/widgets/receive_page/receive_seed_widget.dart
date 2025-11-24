import 'package:cake_wallet/utils/address_formatter.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_list_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class ReceiveSeedWidget extends StatelessWidget {
  const ReceiveSeedWidget({super.key, required this.addressListViewModel});

  final WalletAddressListViewModel addressListViewModel;

  static const List<String> dummyWalletStrings = [
    'bc1q',
    'xy2k',
    'gdyg',
    'jrsq',
    'tzq2',
    'n0yr',
    'f249',
    '3p83',
    'kkfj',
    'hx0wlh',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 80.0),
      child: Observer(
        builder: (_) => AddressFormatter.buildSegmentedAddress(
          address: addressListViewModel.uri.address,
          walletType: addressListViewModel.type,
          textAlign: TextAlign.center,
          evenTextStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
      ),
    );
  }
}
