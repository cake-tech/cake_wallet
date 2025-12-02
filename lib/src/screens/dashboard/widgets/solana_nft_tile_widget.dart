import 'package:flutter/material.dart';
import 'package:cake_wallet/entities/solana_nft_asset_model.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/dashboard/pages/nft_details_page.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';

class SolanaNFTTileWidget extends StatelessWidget {
  const SolanaNFTTileWidget({super.key, required this.nftAsset});

  final SolanaNFTAssetModel nftAsset;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          Routes.nftDetailsPage,
          arguments: NFTDetailsPageArguments(
            isSolanaNFT: true,
            solanaNFTAssetModel: nftAsset,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline,
            width: 0.0,
          ),
          color: Theme.of(context).colorScheme.surfaceContainer,
        ),
        child: Row(
          children: [
            Container(
              height: 100,
              width: 100,
              margin: const EdgeInsets.all(8),
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24.0),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                  width: 0.0,
                ),
                color: Theme.of(context).colorScheme.surface,
              ),
              child: CakeImageWidget(
                imageUrl: nftAsset.imageOriginalUrl,
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Symbol: ${nftAsset.symbol ?? '---'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    (nftAsset.name?.isNotEmpty ?? false)
                        ? nftAsset.name!
                        : (nftAsset.symbol ?? '---'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.onSurface,
                      height: 1,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
