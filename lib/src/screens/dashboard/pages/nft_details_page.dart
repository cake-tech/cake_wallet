import 'package:flutter/material.dart';
import 'package:cake_wallet/entities/solana_nft_asset_model.dart';
import 'package:cake_wallet/entities/wallet_nft_response.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/menu_widget.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/src/widgets/gradient_background.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';

class NFTDetailsPage extends BasePage {
  NFTDetailsPage({
    required this.dashboardViewModel,
    required this.arguments,
    Key? key,
  });

  final DashboardViewModel dashboardViewModel;
  final NFTDetailsPageArguments arguments;

  @override
  bool get gradientBackground => true;

  @override
  Widget Function(BuildContext, Widget) get rootWrapper =>
      (BuildContext context, Widget scaffold) => GradientBackground(scaffold: scaffold);

  @override
  bool get resizeToAvoidBottomInset => false;

  @override
  Widget get endDrawer => MenuWidget(
        dashboardViewModel,
        const ValueKey('nft_details_page_menu_widget_key'),
      );

  @override
  Widget trailing(BuildContext context) {
    final menuButton = Image.asset(
      'assets/images/menu.png',
      color: Theme.of(context).colorScheme.onSurface,
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
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24.0),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline,
            width: 1,
          ),
          color: Theme.of(context).colorScheme.surface,
        ),
        child: arguments.isSolanaNFT
            ? SolanaNFTDetailsWidget(
                solanaNftAsset: arguments.solanaNFTAssetModel,
              )
            : EVMChainNFTDetailsWidget(
                nftAsset: arguments.nftAsset,
              ),
      ),
    );
  }
}

class _NFTImageWidget extends StatelessWidget {
  final String? imageUrl;

  const _NFTImageWidget({Key? key, this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.sizeOf(context).height / 2.5,
      width: double.infinity,
      margin: const EdgeInsets.all(8),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
          width: 1,
        ),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: CakeImageWidget(imageUrl: imageUrl),
    );
  }
}

class EVMChainNFTDetailsWidget extends StatelessWidget {
  final NFTAssetModel? nftAsset;

  const EVMChainNFTDetailsWidget({Key? key, this.nftAsset}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (nftAsset == null) {
      return Center(child: Text(S.current.no_extra_detail));
    }

    final metadata = nftAsset!.normalizedMetadata;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _NFTImageWidget(imageUrl: metadata?.imageUrl),
        const SizedBox(height: 16),
        _NFTSingleInfoTile(
          infoType: S.current.name,
          infoValue: metadata?.name ?? '---',
        ),
        if (metadata?.description != null) ...[
          const SizedBox(height: 16),
          _NFTSingleInfoTile(
            infoType: S.current.description,
            infoValue: metadata!.description ?? '---',
          ),
        ],
        const SizedBox(height: 16),
        _NFTSingleInfoTile(
          infoType: S.current.contractName,
          infoValue: nftAsset!.name ?? '---',
        ),
        const SizedBox(height: 8),
        _NFTSingleInfoTile(
          infoType: S.current.contractSymbol,
          infoValue: nftAsset!.symbol ?? '---',
        ),
      ],
    );
  }
}

class SolanaNFTDetailsWidget extends StatelessWidget {
  final SolanaNFTAssetModel? solanaNftAsset;

  const SolanaNFTDetailsWidget({Key? key, this.solanaNftAsset}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (solanaNftAsset == null) {
      return Center(child: Text(S.current.no_extra_detail));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _NFTImageWidget(imageUrl: solanaNftAsset?.imageOriginalUrl),
        const SizedBox(height: 16),
        _NFTSingleInfoTile(
          infoType: S.current.name,
          infoValue: solanaNftAsset?.name ?? '---',
        ),
        if (solanaNftAsset?.description != null) ...[
          const SizedBox(height: 16),
          _NFTSingleInfoTile(
            infoType: S.current.description,
            infoValue: solanaNftAsset!.description ?? '---',
          ),
        ],
        const SizedBox(height: 16),
        _NFTSingleInfoTile(
          infoType: S.current.mint_address,
          infoValue: solanaNftAsset?.mint ?? '---',
        ),
        const SizedBox(height: 16),
        _NFTSingleInfoTile(
          infoType: S.current.contractName,
          infoValue: solanaNftAsset?.contract?.name ?? '---',
        ),
        const SizedBox(height: 16),
        _NFTSingleInfoTile(
          infoType: S.current.contractSymbol,
          infoValue: solanaNftAsset?.contract?.symbol ?? '---',
        ),
        const SizedBox(height: 16),
        _NFTSingleInfoTile(
          infoType: S.current.collection_name,
          infoValue: solanaNftAsset?.collection?.name ?? '---',
        ),
        const SizedBox(height: 16),
        _NFTSingleInfoTile(
          infoType: S.current.collection_description,
          infoValue: solanaNftAsset?.collection?.description ?? '---',
        ),
        const SizedBox(height: 16),
        _NFTSingleInfoTile(
          infoType: S.current.collection_address,
          infoValue: solanaNftAsset?.collection?.collectionAddress ?? '---',
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _NFTSingleInfoTile extends StatelessWidget {
  final String infoType;
  final String infoValue;

  const _NFTSingleInfoTile({
    required this.infoType,
    required this.infoValue,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            infoType,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            infoValue,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class NFTDetailsPageArguments {
  NFTDetailsPageArguments({
    this.nftAsset,
    this.solanaNFTAssetModel,
    required this.isSolanaNFT,
  });

  final NFTAssetModel? nftAsset;
  final SolanaNFTAssetModel? solanaNFTAssetModel;
  final bool isSolanaNFT;
}
