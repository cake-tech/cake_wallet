import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter/material.dart";

class TokenChainDisplay extends StatelessWidget {
  const TokenChainDisplay({required this.size, required this.asset, super.key});

  final CryptoCurrency asset;
  final double size;

  static const double _chainIconSizeFactor = 0.35;

  double get _chainIconSize => size * _chainIconSizeFactor;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size+(_chainIconSize/2),
        height: size+(_chainIconSize/2),
        child: Stack(
          children: [
            CakeImageWidget(
              imageUrl: asset.iconPath ?? "",
              width: size,
            ),
            if ((asset.chainIconPath ?? "").isNotEmpty)
              Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  decoration: ShapeDecoration(
                    shape: RoundedSuperellipseBorder(
                      borderRadius: BorderRadius.circular(5),
                      side: const BorderSide(color: Colors.black),
                    ),
                    color: Colors.white,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: CakeImageWidget(
                      imageUrl: asset.chainIconPath,
                      width: _chainIconSize,
                      height: _chainIconSize,
                      colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
}
