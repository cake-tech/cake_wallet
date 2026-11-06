import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/defi/defi_scaffold.dart";
import "package:cake_wallet/new-ui/widgets/morpho/morpho_rows.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/src/widgets/new_list_row/new_list_section.dart";
import "package:flutter/material.dart";

class MorphoYieldByAssetSheet extends StatelessWidget {
  const MorphoYieldByAssetSheet({required this.apy, super.key});

  final double? apy;

  static Future<void> show({required BuildContext context, required double? apy}) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => MorphoYieldByAssetSheet(apy: apy),
      );

  @override
  Widget build(BuildContext context) => DefiScaffold(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ModalTopBar(
              title: S.of(context).yield_by_asset,
              leadingIcon: const Icon(Icons.close),
              leadingSemanticLabel: S.of(context).close,
              onLeadingPressed: Navigator.of(context).pop,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 32),
              child: Column(
                spacing: 24,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 27),
                    child: Text(
                      S.of(context).morpho_accepted_assets,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  NewListSections(
                    sections: {
                      "assets": [
                        morphoUsdcRow(
                          trailingText: apy == null ? null : morphoApyText(context, apy!),
                        ),
                      ],
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
