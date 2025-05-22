import 'package:cake_wallet/entities/wallet_nft_response.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/dashboard/pages/nft_details_page.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:flutter/material.dart';

class NFTTileWidget extends StatelessWidget {
  const NFTTileWidget({super.key, required this.nftAsset});

  final NFTAssetModel nftAsset;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushNamed(
        context,
        Routes.nftDetailsPage,
        arguments: NFTDetailsPageArguments(
          isSolanaNFT: false,
          nftAsset: nftAsset,
        ),
      ),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(left: 16, right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30.0),
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
              clipBehavior: Clip.hardEdge,
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24.0),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                  width: 0.0,
                ),
                color: Theme.of(context).colorScheme.surface,
              ),
              child: CakeImageWidget(
                imageUrl: nftAsset.normalizedMetadata?.imageUrl,
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${nftAsset.name ?? '---'} - ${nftAsset.symbol ?? '---'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1,
                        ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    nftAsset.normalizedMetadata?.name ?? nftAsset.name ?? "---",
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
