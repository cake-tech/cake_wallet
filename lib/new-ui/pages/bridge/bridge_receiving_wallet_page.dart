import 'package:cake_wallet/view_model/bridge/bridge_receiving_wallet_option.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/pages/bridge/bridge_confirm_sheet.dart';
import 'package:cake_wallet/new-ui/pages/bridge/bridge_receive_address_input_page.dart';
import 'package:cake_wallet/new-ui/widgets/keyboard_hide_overlay.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/src/widgets/new_list_row/list_Item_style_wrapper.dart';
import 'package:cake_wallet/view_model/bridge/bridge_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class BridgeReceivingWalletPage extends StatefulWidget {
  const BridgeReceivingWalletPage(this.bridgeViewModel);

  final BridgeViewModel bridgeViewModel;

  @override
  State<BridgeReceivingWalletPage> createState() => _BridgeReceivingWalletPageState();
}

class _BridgeReceivingWalletPageState extends State<BridgeReceivingWalletPage> {
  BridgeViewModel get bridgeViewModel => widget.bridgeViewModel;

  @override
  void initState() {
    super.initState();
    bridgeViewModel.loadReceivingWalletOptions();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardHideOverlay(
      unfocusOnTap: true,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            ModalTopBar(
              title: 'Receiving Wallet',
              leadingIcon: const Icon(Icons.arrow_back_ios_new, size: 18),
              leadingSemanticLabel: S.of(context).seed_alert_back,
              onLeadingPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 48),
            Expanded(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Observer(
                    builder: (_) {
                      final chain = bridgeViewModel.destinationChainInfo;

                      final chainName = chain?.name ?? '';

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 8),
                          Center(
                            child: CakeImageWidget(
                              borderRadius: 8,
                              imageUrl: chainName.isNotEmpty
                                  ? 'assets/new-ui/crypto_full_icons/${chainName.toLowerCase()}.svg'
                                  : null,
                              width: 72,
                              height: 72,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Select a $chainName wallet or address to send '
                            'the bridged USDT0 to.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 14,
                                  letterSpacing: -0.07,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 24),
                          if (bridgeViewModel.isBridgeReceivingWalletListLoading)
                            const Expanded(
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else
                            Expanded(
                              child: ListView(
                                padding: const EdgeInsets.only(bottom: 16),
                                children: _receivingListRows(context),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _receivingListRows(BuildContext context) {
    final options = bridgeViewModel.bridgeReceivingWalletOptions;
    final rows = <Widget>[];

    for (int i = 0; i < options.length; i++) {
      final option = options[i];

      if (i > 0) rows.add(const SizedBox(height: 12));

      rows.add(
        _BridgeReceivingWalletRow(
          option: option,
          onTap: () {
            bridgeViewModel.setRecipientAddress(option.address, destWalletName: option.name);

            showMaterialModalBottomSheet<void>(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (ctx) => BridgeConfirmSheet(bridgeViewModel),
            );
          },
        ),
      );
    }

    if (options.isNotEmpty) rows.add(const SizedBox(height: 12));

    rows.add(
      ListItemStyleWrapper(
        isFirstInSection: true,
        isLastInSection: true,
        height: 48,
        contentPadding: const EdgeInsets.all(12),
        onTap: () {
          showMaterialModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (ctx) => BridgeReceiveAddressInputPage(bridgeViewModel: bridgeViewModel),
          );
        },
        builder: (ctx, textStyle, _) {
          final scheme = Theme.of(ctx).colorScheme;
          return Row(
            children: [
              Icon(
                Icons.edit_outlined,
                size: 24,
                color: scheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Input an Address',
                  style: textStyle.copyWith(
                    color: scheme.primary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return rows;
  }
}

class _BridgeReceivingWalletRow extends StatelessWidget {
  const _BridgeReceivingWalletRow({
    required this.option,
    required this.onTap,
  });

  final BridgeReceivingWalletOption option;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasGroupRow = option.groupLabel != null;

    return ListItemStyleWrapper(
      onTap: onTap,
      isFirstInSection: true,
      isLastInSection: true,
      height: hasGroupRow ? 62.0 : 48.0,
      builder: (ctx, textStyle, labelStyle) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.name,
                    style: textStyle.copyWith(letterSpacing: -0.07),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (hasGroupRow) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 16,
                          color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            option.groupLabel!,
                            style: labelStyle.copyWith(
                              fontSize: 12,
                              letterSpacing: -0.06,
                              color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (option.isCurrent) ...[
                          const SizedBox(width: 8),
                          Text(
                            'Current',
                            style: textStyle.copyWith(
                              fontSize: 12,
                              color: Theme.of(ctx).colorScheme.primary,
                              letterSpacing: -0.06,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
            CakeImageWidget(
              imageUrl: 'assets/new-ui/arrow_forward.svg',
              height: 16,
              color: Theme.of(ctx).colorScheme.onSurfaceVariant,
            ),
          ],
        );
      },
    );
  }
}
