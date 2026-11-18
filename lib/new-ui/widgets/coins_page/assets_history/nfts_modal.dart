import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/src/screens/dashboard/pages/nft_listing_page.dart";
import "package:cake_wallet/view_model/dashboard/nft_view_model.dart";
import "package:flutter/material.dart";
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";

class NFTsModal extends StatelessWidget {
  const NFTsModal({required this.nftViewModel, super.key});

  final NFTViewModel nftViewModel;

  @override
  Widget build(BuildContext context) => Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        child: Column(
          children: [
            ModalTopBar(
              title: S.of(context).nfts,
              leadingIcon: const Icon(Icons.close),
              leadingSemanticLabel: S.of(context).close,
              onLeadingPressed: Navigator.of(context).maybePop,
            ),
            Expanded(
              child: CustomScrollView(
                physics: const ClampingScrollPhysics(),
                controller: ModalScrollController.of(context),
                slivers: [NFTListingPage(nftViewModel: nftViewModel)],
              ),
            ),
          ],
        ),
      );
}
