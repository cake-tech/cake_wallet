import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/nft_tile_widget.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/solana_nft_tile_widget.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/view_model/dashboard/nft_view_model.dart';
import 'package:cw_core/wallet_type.dart';

class NFTListingPage extends StatefulWidget {
  final NFTViewModel nftViewModel;

  const NFTListingPage({super.key, required this.nftViewModel});

  @override
  State<NFTListingPage> createState() => _NFTListingPageState();
}

class _NFTListingPageState extends State<NFTListingPage> {
  @override
  void initState() {
    super.initState();

    fetchNFTsForWallet();
  }

  Future<void> fetchNFTsForWallet() async {
    await widget.nftViewModel.getNFTAssetByWallet();
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (context) {
        return Column(
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: PrimaryButton(
                text: S.current.import,
                color: Theme.of(context).colorScheme.surfaceContainer,
                textColor: Theme.of(context).colorScheme.onSecondaryContainer,
                onPressed: () => Navigator.pushNamed(
                  context,
                  Routes.importNFTPage,
                  arguments: widget.nftViewModel,
                ),
              ),
            ),
            if (widget.nftViewModel.isLoading)
              Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: NFTListWidget(nftViewModel: widget.nftViewModel),
              ),
          ],
        );
      },
    );
  }
}

class NFTListWidget extends StatelessWidget {
  const NFTListWidget({required this.nftViewModel, super.key});

  final NFTViewModel nftViewModel;

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (context) {
        final isSolana = nftViewModel.appStore.wallet!.type == WalletType.solana;

        final emptyMessage = Center(
          child: Text(
            S.current.noNFTYet,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        );

        if (isSolana) {
          if (nftViewModel.solanaNftAssetModels.isEmpty) return emptyMessage;

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemCount: nftViewModel.solanaNftAssetModels.length,
            itemBuilder: (context, index) {
              final nftAsset = nftViewModel.solanaNftAssetModels[index];
              return SolanaNFTTileWidget(nftAsset: nftAsset);
            },
          );
        } else {
          if (nftViewModel.nftAssetByWalletModels.isEmpty) return emptyMessage;

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemCount: nftViewModel.nftAssetByWalletModels.length,
            itemBuilder: (context, index) {
              final nftAsset = nftViewModel.nftAssetByWalletModels[index];
              return NFTTileWidget(nftAsset: nftAsset);
            },
          );
        }
      },
    );
  }
}
