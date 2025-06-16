import 'package:cake_wallet/entities/parsed_address.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/address_book/widgets/addresses_expansion_tile_widget.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/themes/utils/custom_theme_colors.dart';
import 'package:cake_wallet/utils/address_formatter.dart';
import 'package:cake_wallet/utils/image_utill.dart';
import 'package:cake_wallet/view_model/contact_list/contact_view_model.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EditNewContactPage extends BasePage {
  EditNewContactPage({required this.contactViewModel});

  final ContactViewModel contactViewModel;

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
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Image(
              width: 24,
              height: 24,
              image: contactViewModel.avatarProvider,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            contactViewModel.name,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: titleColor(context),
            ),
          ),
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
        ? CustomThemeColors.backgroundGradientColorDark.withAlpha(100)
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
                        imagePath: contactViewModel.sourceType.iconPath, height: 24, width: 24),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        contactViewModel.sourceType.label +
                            ' - ' +
                            contactViewModel.handle,
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
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          children: contactViewModel.parsedAddressesByCurrency.keys
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
          ContactAddressesExpansionTile(
            key: ValueKey(contactViewModel.name),
            title: Text('Manual Addresses'),
            fillColor: fillColor,
            manualByCurrency: contactViewModel.manualAddressesByCurrency,
            onCopyPressed: (address) async => await Clipboard.setData(ClipboardData(text: address)),
            onEditPressed: (cur, lbl) {
              Navigator.pushNamed(
                context,
                Routes.editAddressPage,
                arguments: [
                  contactViewModel.contactRecord,
                  cur,
                  lbl,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
