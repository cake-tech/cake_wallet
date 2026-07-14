import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/bridge/expandable_details_card.dart';
import 'package:cake_wallet/view_model/bridge/bridge_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class ConfirmDetailsCard extends StatelessWidget {
  const ConfirmDetailsCard({required this.bridgeViewModel});

  final BridgeViewModel bridgeViewModel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Observer(
      builder: (_) {
        final feeParts = <String>[
          bridgeViewModel.quoteNativeFeeFormattedForDisplay,
          bridgeViewModel.quoteNativeFiatFeeFormattedForDisplay,
        ];
        final feeLine = feeParts.join(' ');

        return Container(
          decoration: BoxDecoration(
            color: scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              ExpandableBridgeDetailRow(
                label: S.of(context).from,
                title: bridgeViewModel.wallet.name,
                address: bridgeViewModel.sourceAddress,
                showChevron: true,
              ),
              Divider(
                height: 1,
                color: scheme.surfaceContainerHigh,
              ),
              ExpandableBridgeDetailRow(
                label: S.of(context).to,
                title: bridgeViewModel.destinationWalletName ??
                    bridgeViewModel.recipientAddress.trim(),
                address: bridgeViewModel.recipientAddress.trim(),
                showChevron: bridgeViewModel.destinationWalletName != null,
              ),
              Divider(
                height: 1,
                color: scheme.surfaceContainerHigh,
              ),
              ExpandableBridgeDetailRow(
                label: S.of(context).fee,
                title: feeLine,
                showChevron: false,
              ),
            ],
          ),
        );
      },
    );
  }
}
