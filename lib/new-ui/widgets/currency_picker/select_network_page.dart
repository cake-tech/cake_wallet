import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_args.dart';
import 'package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_list_container.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/currency_for_wallet_type.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';

class SelectNetworkPage extends StatelessWidget {
  const SelectNetworkPage({
    super.key,
    required this.assetTitle,
    required this.assetFullName,
    required this.assetIconPath,
    required this.variants,
    required this.onSelected,
  });

  final String assetTitle;
  final String? assetFullName;
  final String? assetIconPath;
  final List<CryptoCurrency> variants;
  final ValueChanged<CryptoCurrency> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          children: [
            ModalTopBar(
              title: S.of(context).select_network_title,
              leadingIcon: const Icon(Icons.arrow_back),
              leadingSemanticLabel: S.of(context).seed_alert_back,
              onLeadingPressed: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(height: 24),
            // Illustration of the asset named by the title below it.
            ExcludeSemantics(
              child: CakeImageWidget(
                imageUrl: assetIconPath,
                width: 75,
                height: 75,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              assetTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                S.of(context).select_network_subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: colors.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  CurrencyPickerListContainer(
                    rows: [
                      for (final variant in variants)
                        _NetworkRow(
                          variant: variant,
                          onTap: () {
                            final nav = Navigator.of(context);
                            onSelected(variant);
                            if (nav.canPop()) nav.pop();
                            if (nav.canPop()) nav.pop();
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NetworkRow extends StatelessWidget {
  const _NetworkRow({required this.variant, required this.onTap});

  final CryptoCurrency variant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final wt = cryptoCurrencyOrTokenToWalletType(variant);
    final networkIconPath =
        wt != null ? getCryptoCurrencyIconForWalletListItem(wt) : variant.iconPath;
    final networkName = chainNameForCurrency(variant);
    return MergeSemantics(
      child: Semantics(
        button: true,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: CakeImageWidget(
                    imageUrl: networkIconPath,
                    width: 28,
                    height: 28,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    networkName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
                ExcludeSemantics(
                  child: Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
