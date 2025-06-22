import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/parse_address_from_domain.dart';
import 'package:cake_wallet/entities/parsed_address.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/address_book/entities/address_edit_request.dart';
import 'package:cake_wallet/src/screens/address_book/widgets/addresses_expansion_tile_widget.dart';
import 'package:cake_wallet/src/screens/address_book/widgets/rounded_icon_button.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/themes/utils/custom_theme_colors.dart';
import 'package:cake_wallet/utils/image_utill.dart';
import 'package:cake_wallet/view_model/contact_list/contact_view_model.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class EditContactPage extends BasePage {
  EditContactPage({required this.contactViewModel});

  final ContactViewModel contactViewModel;

  @override
  Widget middle(BuildContext context) {
    return Observer(
      builder: (_) => Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Image(
                    width: 24,
                    height: 24,
                    image: contactViewModel.avatar,
                    fit: BoxFit.cover)),
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
      ),
    );
  }

  @override
  Widget trailing(BuildContext context) {
    final onHandlerSearch = (query) async {
      final address = await getIt
          .get<AddressResolverService>()
          .resolve(query: query as String, wallet: contactViewModel.wallet);
      return address;
    };
    return SizedBox(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          RoundedIconButton(icon: Icons.add, onPressed: () {
            Navigator.pushNamed(
              context,
              Routes.newContactWelcomePage,
              arguments: [onHandlerSearch, true, contactViewModel.record],
            );
          }),
          const SizedBox(width: 8),
          RoundedIconButton(icon: Icons.edit, onPressed: () {
            Navigator.pushNamed(
              context,
              Routes.editContactGroupPage,
              arguments: contactViewModel,
            );
          }),
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

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ContactAddressesExpansionTile(
              key: ValueKey(contactViewModel.name),
              title: Text('Manual Addresses'),
              fillColor: fillColor,
              manualByCurrency: contactViewModel.manual,
              onCopyPressed: (address) async =>
                  await Clipboard.setData(ClipboardData(text: address)),
              onEditPressed: (cur, lbl) {
                Navigator.pushNamed(
                  context,
                  Routes.editAddressPage,
                  arguments: AddressEditRequest.address(
                    contact: contactViewModel.record,
                    currency: cur,
                    label: lbl,
                    kindIsManual: true,
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            ...contactViewModel.parsedBlocks.entries.map((entry) {
              final String handle = entry.key;
              final stringSrc = handle.split('-').first;
              final Map<CryptoCurrency, Map<String, String>> byCurrency = entry.value;

              final src = AddressSourceNameParser.fromLabel(stringSrc);

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ContactAddressesExpansionTile(
                  key: ValueKey('${contactViewModel.name}'),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ImageUtil.getImageFromPath(
                        imagePath: src.iconPath,
                        height: 24,
                        width: 24,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          handle,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  fillColor: fillColor,
                  manualByCurrency: byCurrency,
                  onCopyPressed: (addr) => Clipboard.setData(ClipboardData(text: addr)),
                  onEditPressed: (cur, lbl) {
                    Navigator.pushNamed(
                      context,
                      Routes.editAddressPage,
                      arguments: AddressEditRequest.address(
                        contact: contactViewModel.record,
                        currency: cur,
                        label: lbl,
                        kindIsManual: false,
                        handle: handle,
                        handleKey: entry.key,
                      ),
                    );
                  },
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
