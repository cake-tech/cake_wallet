import 'package:cake_wallet/entities/wallet_nft_response.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/menu_widget.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/src/widgets/gradient_background.dart';
import 'package:cake_wallet/themes/extensions/balance_page_theme.dart';
import 'package:cake_wallet/themes/extensions/dashboard_page_theme.dart';
import 'package:cake_wallet/themes/extensions/sync_indicator_theme.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:flutter/material.dart';

class NFTDetailsPage extends BasePage {
  NFTDetailsPage({required this.dashboardViewModel, required this.nftAsset});

  final DashboardViewModel dashboardViewModel;
  final NFTAssetModel nftAsset;

  @override
  bool get gradientBackground => true;

  @override
  Widget Function(BuildContext, Widget) get rootWrapper =>
      (BuildContext context, Widget scaffold) =>
          GradientBackground(scaffold: scaffold);

  @override
  bool get resizeToAvoidBottomInset => false;

  @override
  Widget get endDrawer => MenuWidget(dashboardViewModel);

  @override
  Widget trailing(BuildContext context) {
    final menuButton = Image.asset(
      'assets/images/menu.png',
      color:
          Theme.of(context).extension<DashboardPageTheme>()!.pageTitleTextColor,
    );

    return Container(
      alignment: Alignment.centerRight,
      width: 40,
      child: TextButton(
        // FIX-ME: Style
        //highlightColor: Colors.transparent,
        //splashColor: Colors.transparent,
        //padding: EdgeInsets.all(0),
        onPressed: () => onOpenEndDrawer(),
        child: Semantics(label: S.of(context).wallet_menu, child: menuButton),
      ),
    );
  }

  @override
  Widget body(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30.0),
              border: Border.all(
                color: Theme.of(context)
                    .extension<BalancePageTheme>()!
                    .cardBorderColor,
                width: 1,
              ),
              color: Theme.of(context)
                  .extension<SyncIndicatorTheme>()!
                  .syncedBackgroundColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: MediaQuery.sizeOf(context).height / 2.5,
                  width: double.infinity,
                  clipBehavior: Clip.hardEdge,
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(
                      color: Theme.of(context)
                          .extension<BalancePageTheme>()!
                          .cardBorderColor,
                      width: 1,
                    ),
                    color: Theme.of(context)
                        .extension<SyncIndicatorTheme>()!
                        .syncedBackgroundColor,

                  ),
                  child: CakeImageWidget(
                    imageUrl: nftAsset.normalizedMetadata?.imageUrl,
                  ),
                ),
                SizedBox(height: 16),
                _NFTSingleInfoTile(
                  infoType: S.current.name,
                  infoValue: nftAsset.normalizedMetadata?.name ?? '---',
                ),

                if (nftAsset.normalizedMetadata?.description != null) ...[
                  SizedBox(height: 16),
                  _NFTSingleInfoTile(
                    infoType: S.current.description,
                    infoValue: nftAsset.normalizedMetadata?.description ?? '---',
                  ),
                ],

                SizedBox(height: 16),
                _NFTSingleInfoTile(
                  infoType: S.current.contractName,
                  infoValue: nftAsset.name ?? '---',
                ),
                SizedBox(height: 8),
                _NFTSingleInfoTile(
                  infoType: S.current.contractSymbol,
                  infoValue: nftAsset.symbol ?? '---',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NFTSingleInfoTile extends StatelessWidget {
  const _NFTSingleInfoTile({
    required this.infoType,
    required this.infoValue,
  });

  final String infoType;
  final String infoValue;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
infoType,
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'Lato',
              fontWeight: FontWeight.w400,
              color: Theme.of(context)
                  .extension<BalancePageTheme>()!
                  .labelTextColor,
              height: 1,
            ),
          ),
          SizedBox(height: 8),
          Text(
            infoValue,
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Lato',
              fontWeight: FontWeight.w600,
              color: Theme.of(context)
                  .extension<BalancePageTheme>()!
                  .assetTitleColor,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
