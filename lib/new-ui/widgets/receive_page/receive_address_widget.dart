import "package:cake_wallet/utils/address_formatter.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/material.dart";

class ReceiveAddressWidget extends StatelessWidget {
  const ReceiveAddressWidget({
    required this.address,
    required this.walletType,
    super.key,
  });

  final String address;
  final WalletType walletType;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 50),
        child: AddressFormatter.buildSegmentedAddress(
          address: address,
          walletType: walletType,
          textAlign: TextAlign.center,
          evenTextStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
                fontFamily: "IBM Plex Mono",
              ),
        ),
      );
}
