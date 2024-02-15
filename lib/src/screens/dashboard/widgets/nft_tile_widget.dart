import 'package:cake_wallet/entities/wallet_nft_response.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/themes/extensions/balance_page_theme.dart';
import 'package:cake_wallet/themes/extensions/sync_indicator_theme.dart';
import 'package:flutter/material.dart';

class NFTTileWidget extends StatelessWidget {
  const NFTTileWidget({super.key, required this.nftAsset});

  final NFTAssetModel nftAsset;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, Routes.nftDetailsPage, arguments: nftAsset),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(left: 16, right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30.0),
          border: Border.all(
              color: Theme.of(context).extension<BalancePageTheme>()!.cardBorderColor, width: 1),
          color: Theme.of(context).extension<SyncIndicatorTheme>()!.syncedBackgroundColor,
        ),
        child: Row(
          children: [
            Container(
              height: 100,
              width: 100,
              clipBehavior: Clip.hardEdge,
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(
                  color: Theme.of(context).extension<BalancePageTheme>()!.cardBorderColor,
                  width: 1,
                ),
                color: Theme.of(context).extension<SyncIndicatorTheme>()!.syncedBackgroundColor,
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
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'Lato',
                      fontWeight: FontWeight.w400,
                      color: Theme.of(context).extension<BalancePageTheme>()!.labelTextColor,
                      height: 1,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    nftAsset.normalizedMetadata?.name ?? nftAsset.name ?? "---",
                    style: TextStyle(
                      fontSize: 20,
                      fontFamily: 'Lato',
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).extension<BalancePageTheme>()!.assetTitleColor,
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
