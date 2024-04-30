import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/nft_tile_widget.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/themes/extensions/dashboard_page_theme.dart';
import 'package:cake_wallet/themes/extensions/exchange_page_theme.dart';
import 'package:cake_wallet/themes/extensions/sync_indicator_theme.dart';
import 'package:cake_wallet/view_model/dashboard/nft_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class NFTListingPage extends StatelessWidget {
  final NFTViewModel nftViewModel;

  const NFTListingPage({super.key, required this.nftViewModel});
  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (context) {
        return Column(
          children: [
            SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: PrimaryButton(
                text: S.current.import,
                color: Theme.of(context)
                    .extension<SyncIndicatorTheme>()!
                    .syncedBackgroundColor,
                textColor: Colors.white,
                onPressed: () => Navigator.pushNamed(
                  context,
                  Routes.importNFTPage,
                  arguments: nftViewModel,
                ),
              ),
            ),
            if (nftViewModel.isLoading)
              Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                    backgroundColor: Theme.of(context).extension<DashboardPageTheme>()!.textColor,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context)
                          .extension<ExchangePageTheme>()!
                          .firstGradientBottomPanelColor,
                    ),
                  ),
                ),
              ),
            if (!nftViewModel.isLoading)
              Expanded(
                child: nftViewModel.nftAssetByWalletModels.isEmpty
                    ? Center(
                        child: Text(
                          S.current.noNFTYet,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontFamily: 'Lato',
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context)
                                .extension<DashboardPageTheme>()!
                                .pageTitleTextColor,
                            height: 1,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 16),
                        separatorBuilder: (context, index) => SizedBox(height: 8),
                        itemCount: nftViewModel.nftAssetByWalletModels.length,
                        itemBuilder: (context, index) {
                          final nftAsset = nftViewModel.nftAssetByWalletModels[index];
                          return NFTTileWidget(nftAsset: nftAsset);
                        },
                      ),
              )
          ],
        );
      },
    );
  }
}
