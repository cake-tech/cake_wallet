import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_list_view_model.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ReceiveTokenDisplay extends StatelessWidget {
  const ReceiveTokenDisplay({super.key, required this.addressListViewModel});

  final WalletAddressListViewModel addressListViewModel;

  @override
  Widget build(BuildContext context) {
    return  Observer(
      builder: (_)=>Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 8,
        children: [
          Text(
            addressListViewModel.tokenCurrency!.title,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary),
          ),
          Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99999),
                color: Theme.of(context).colorScheme.surfaceContainer),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Row(
                spacing:4,
                children: [
                  SvgPicture.asset(
                    "assets/new-ui/chain_badges/${walletTypeToString(addressListViewModel.wallet.type).toLowerCase()}.svg",
                    width: 16,
                    height: 16,
                    colorFilter: ColorFilter.mode(
                        Theme.of(context).colorScheme.primary,
                        BlendMode.srcIn),
                  ),
                  Text(walletTypeToString(addressListViewModel.wallet.type),
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.primary)),
                  SizedBox()
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
