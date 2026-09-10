import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/keyboard_hide_overlay.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/widgets/new_list_row/list_item_regular_row_widget.dart';
import 'package:cake_wallet/src/widgets/new_list_row/new_list_section.dart';
import 'package:cake_wallet/view_model/bridge/bridge_view_model.dart';
import 'package:cw_core/generate_name.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class BridgeNetworkPage extends StatelessWidget {
  const BridgeNetworkPage(this.bridgeViewModel);

  final BridgeViewModel bridgeViewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return KeyboardHideOverlay(
      unfocusOnTap: true,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            ModalTopBar(
              title: 'Destination Network',
              leadingIcon: const Icon(Icons.arrow_back_ios_new, size: 18),
              leadingSemanticLabel: S.of(context).seed_alert_back,
              onLeadingPressed: () => Navigator.of(context).pop(),
            ),
            SizedBox(height: 48),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
              child: Text(
                'Select what Network to transfer your assets to',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            SizedBox(height: 24),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  children: [
                    Observer(
                      builder: (_) {
                        return NewListSections(
                          sections: {
                            '': bridgeViewModel.availableDestinationChains.map(
                              (chain) {
                                final chainName = chain.name;
                                return ListItemRegularRow(
                                  iconPath:
                                      'assets/new-ui/crypto_full_icons/${chainName.toLowerCase()}.svg',
                                  keyValue: chain.chainId.toString(),
                                  label: chainName,
                                  onTap: () {
                                    bridgeViewModel.setDestinationChain(chain.chainId);
                                    Navigator.pushNamed(context, Routes.bridgeReceivingWalletPage,
                                        arguments: bridgeViewModel);
                                  },
                                );
                              },
                            ).toList(),
                          },
                        );
                      },
                    ),
                    SizedBox(height: 24),
                    Observer(
                      builder: (_) {
                        final src = bridgeViewModel.wallet.type.name;

                        return ListItemRegularRowWidget(
                          isFirstInSection: true,
                          isLastInSection: true,
                          keyValue: 'sending_from',
                          label: 'Sending from',
                          trailingIconPath: 'assets/new-ui/chain_badges/${src.toLowerCase()}.svg',
                          trailingText: src.capitalized(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
