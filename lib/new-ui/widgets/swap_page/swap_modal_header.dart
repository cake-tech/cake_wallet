import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/evm_network.dart";
import 'package:flutter/material.dart';

class SwapModalHeader extends StatelessWidget {
  const SwapModalHeader({super.key, required this.from, required this.to});

  final CryptoCurrency from;
  final CryptoCurrency to;

  @override
  Widget build(BuildContext context) {
    final fromNetwork = AddedNetworkCurrency.of(from);
    final toNetwork = AddedNetworkCurrency.of(to);

    return Row(
      spacing: 8,
      children: [
        SizedBox(
          height: 36,
          width: 36,
          child: Stack(
            children: [
              CakeImageWidget(
                imageUrl: from.iconPath,
                width: 24,
                height: 24,
                isRoundedSquare: fromNetwork != null,
                isOutlined: fromNetwork?.isManual == true,
                fallbackName: fromNetwork?.fullName,
              ),
              Positioned(
                top: 12,
                left: 12,
                child: CakeImageWidget(
                  imageUrl: to.iconPath,
                  width: 24,
                  height: 24,
                  isRoundedSquare: toNetwork != null,
                  isOutlined: toNetwork?.isManual == true,
                  fallbackName: toNetwork?.fullName,
                ),
              ),
            ],
          ),
        ),
        Text(
          S.of(context).swap,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
        )
      ],
    );
  }
}
