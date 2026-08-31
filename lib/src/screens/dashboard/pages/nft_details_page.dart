import 'package:flutter/material.dart';
import 'package:cake_wallet/entities/solana_nft_asset_model.dart';
import 'package:cake_wallet/entities/wallet_nft_response.dart';
import 'package:cake_wallet/generated/i18n.dart';
import "package:cake_wallet/routes.dart";
import 'package:cake_wallet/src/screens/base_page.dart';
import "package:cake_wallet/src/screens/dashboard/pages/nft_send_page.dart";
import 'package:cake_wallet/src/screens/dashboard/widgets/menu_widget.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/src/widgets/gradient_background.dart';
import "package:cake_wallet/src/widgets/primary_button.dart";
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
    return SizedBox.shrink();
    // final menuButton = Image.asset(
    //   'assets/images/menu.png',
    //   color: Theme.of(context).colorScheme.onSurface,
    // );
    //
    // return Container(
    //   alignment: Alignment.centerRight,
    //   width: 40,
    //   child: TextButton(
    //     // FIX-ME: Style
    //     //highlightColor: Colors.transparent,
    //     //splashColor: Colors.transparent,
    //     //padding: EdgeInsets.all(0),
    //     onPressed: () => onOpenEndDrawer(),
    //     child: Semantics(label: S.of(context).wallet_menu, child: menuButton),
    //   ),
    // );
  }

  bool get _canSend =>
      arguments.isSolanaNFT &&
      (arguments.solanaNFTAssetModel?.mint?.isNotEmpty ?? false) &&
      arguments.solanaNFTAssetModel?.isOwned != false;

  @override
  Widget body(BuildContext context) => SingleChildScrollView(
        child: Column(
          children: [
            Container(
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
            if (_canSend)
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
                child: PrimaryButton(
                  text: S.of(context).send,
                  color: Theme.of(context).colorScheme.primary,
                  textColor: Theme.of(context).colorScheme.onPrimary,
                  onPressed: () async {
                    final sent = await Navigator.of(context).pushNamed(
                      Routes.nftSendPage,
                      arguments: NFTSendPageArguments(asset: arguments.solanaNFTAssetModel!),
                    );

                    if (sent == true && context.mounted) {
                      Navigator.of(context).pop(true);
                    }
                  },
                ),
              ),
          ],
        ),
      );
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

    final moreInfoEntries = <MapEntry<String, String>>[
      MapEntry(S.current.mint_address, solanaNftAsset?.mint ?? ""),
      MapEntry(S.current.contractName, solanaNftAsset?.contract?.name ?? ""),
      MapEntry(S.current.contractSymbol, solanaNftAsset?.contract?.symbol ?? ""),
      MapEntry(S.current.collection_name, solanaNftAsset?.collection?.name ?? ""),
      MapEntry(S.current.collection_description, solanaNftAsset?.collection?.description ?? ""),
      MapEntry(S.current.collection_address, solanaNftAsset?.collection?.collectionAddress ?? ""),
    ].where((entry) => entry.value.isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _NFTImageWidget(imageUrl: solanaNftAsset?.imageOriginalUrl),
        const SizedBox(height: 16),
        _NFTSingleInfoTile(
          infoType: S.current.name,
          infoValue: solanaNftAsset?.name ?? '---',
        ),
        if (solanaNftAsset?.isOwned == false) ...[
          const SizedBox(height: 16),
          _NFTSingleInfoTile(
            infoType: S.current.watching,
            infoValue: S.current.nft_not_held_by_wallet,
          ),
        ],
        if (solanaNftAsset?.description?.isNotEmpty ?? false) ...[
          const SizedBox(height: 16),
          _NFTSingleInfoTile(
            infoType: S.current.description,
            infoValue: solanaNftAsset!.description!,
          ),
        ],
        if (moreInfoEntries.isNotEmpty) _NFTMoreInfoSection(entries: moreInfoEntries),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _NFTMoreInfoSection extends StatefulWidget {
  const _NFTMoreInfoSection({required this.entries});

  final List<MapEntry<String, String>> entries;

  @override
  State<_NFTMoreInfoSection> createState() => _NFTMoreInfoSectionState();
}

class _NFTMoreInfoSectionState extends State<_NFTMoreInfoSection> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          InkWell(
            onTap: () => setState(() => isExpanded = !isExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    S.current.show_details,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            for (final entry in widget.entries) ...[
              const SizedBox(height: 16),
              _NFTSingleInfoTile(infoType: entry.key, infoValue: entry.value),
            ],
        ],
      );
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
