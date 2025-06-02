import 'package:cake_wallet/entities/parsed_address.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/themes/utils/custom_theme_colors.dart';
import 'package:cake_wallet/utils/address_formatter.dart';
import 'package:cake_wallet/utils/image_utill.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';

class EditNewContactPage extends BasePage {
  EditNewContactPage({required this.selectedParsedAddress});

  final ParsedAddress selectedParsedAddress;

  Widget _circleIcon(BuildContext context, IconData icon, VoidCallback onPressed) {
    final colorScheme = Theme.of(context).colorScheme;
    return RawMaterialButton(
      onPressed: onPressed,
      fillColor: colorScheme.surfaceContainerHighest,
      elevation: 0,
      constraints: const BoxConstraints.tightFor(width: 24, height: 24),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: const CircleBorder(),
      child: Icon(icon, size: 14, color: colorScheme.onSurface),
    );
  }

  @override
  Widget leading(BuildContext context) {
    return SizedBox(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _circleIcon(context, Icons.favorite_border_outlined, () {}),
          const SizedBox(width: 8),
          _circleIcon(context, Icons.refresh_sharp, () {}),
        ],
      ),
    );
  }

  @override
  Widget middle(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ImageUtil.getImageFromPath(
              imagePath: selectedParsedAddress.profileImageUrl, height: 24, width: 24),
          const SizedBox(width: 12),
          Text('Edit Contact',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 18.0, fontWeight: FontWeight.w600, color: titleColor(context))),
        ],
      ),
    );
  }

  @override
  Widget trailing(BuildContext context) {
    return SizedBox(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _circleIcon(context, Icons.add, () {}),
          const SizedBox(width: 8),
          _circleIcon(context, Icons.edit, () {}),
        ],
      ),
    );
  }

  @override
  Widget body(BuildContext context) {
    final theme = Theme.of(context);
    final fillColor = currentTheme.isDark
        ? CustomThemeColors.backgroundGradientColorDark
        : CustomThemeColors.backgroundGradientColorLight;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 1),
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: const BorderRadius.all(Radius.circular(12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ImageUtil.getImageFromPath(
                        imagePath: selectedParsedAddress.addressSource.iconPath, height: 24, width: 24),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        selectedParsedAddress.addressSource.label +
                            ' - ' +
                            selectedParsedAddress.addressSource.alias,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _circleIcon(context, Icons.edit, () {}),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('Addresses detected:', style: theme.textTheme.bodyMedium),
                      const SizedBox(width: 8),
                      Expanded(                                     // take remaining width
                        child: Wrap(
                          spacing: 8,
                          children: selectedParsedAddress.addressByCurrencyMap.keys
                              .map((currency) => currency.iconPath != null
                              ? Image.asset(currency.iconPath!, height: 24, width: 24)
                              : const SizedBox.shrink())
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ExpansionContactTile(
            fillColor: fillColor,
            selectedParsedAddress: selectedParsedAddress,
          ),
        ],
      ),
    );
  }
}

class ExpansionContactTile extends StatelessWidget {
  const ExpansionContactTile({
    required this.fillColor,
    required this.selectedParsedAddress,
  });

  final Color fillColor;
  final ParsedAddress selectedParsedAddress;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Contact Details',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          color: fillColor,
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: ExpansionTile(
              childrenPadding: EdgeInsets.zero,
              tilePadding: EdgeInsets.zero,
              dense: true,
              iconColor: Theme.of(context).colorScheme.onSurfaceVariant,
              visualDensity: VisualDensity.compact,
              title: Text('Manual Addresses'),
              children: [
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: selectedParsedAddress.addressByCurrencyMap.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final currency = selectedParsedAddress.addressByCurrencyMap.keys.elementAt(index);
                    final address = selectedParsedAddress.addressByCurrencyMap[currency] ?? '';
                    return ListTile(
                      title: Text(currency.title.toLowerCase(), style: Theme.of(context).textTheme.bodyLarge),
                      subtitle: AddressFormatter.buildSegmentedAddress(
                        address: address,
                        walletType: cryptoCurrencyToWalletType(currency),
                        evenTextStyle: Theme.of(context).textTheme.labelMedium!,
                        visibleChunks: 4,
                        shouldTruncate: true,
                      ),
                      leading: ImageUtil.getImageFromPath(imagePath: currency.iconPath ?? '', height: 24, width: 24),
                      dense: true,
                      visualDensity: VisualDensity(horizontal: 0, vertical: -3),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
