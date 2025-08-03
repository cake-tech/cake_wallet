import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/address_resolver/address_resolver_service.dart';
import 'package:cake_wallet/address_resolver/parsed_address.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/address_book/sheet_page.dart';
import 'package:cake_wallet/src/screens/address_book/widgets/addresses_expansion_tile_widget.dart';
import 'package:cake_wallet/src/widgets/rounded_icon_button.dart';
import 'package:cake_wallet/utils/image_utill.dart';
import 'package:cake_wallet/view_model/contact_list/contact_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class ContactPage extends SheetPage {
  ContactPage({required this.contactViewModel});

  final ContactViewModel contactViewModel;

  @override
  Widget? leading(BuildContext context) {
    return RoundedIconButton(
        icon: Icons.refresh_outlined, onPressed: () async => await contactViewModel.refresh());
  }

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
                    width: 30, height: 30, image: contactViewModel.avatar, fit: BoxFit.cover)),
            const SizedBox(width: 12),
            Text(
              contactViewModel.name,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget trailing(BuildContext context) {
    return SizedBox(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          RoundedIconButton(
              icon: Icons.add,
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  Routes.contactWelcomePage,
                  arguments: contactViewModel.record,
                );
              }),
          const SizedBox(width: 8),
          RoundedIconButton(
              icon: Icons.edit,
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  Routes.editContactPage,
                  arguments: contactViewModel,
                );
              }),
        ],
      ),
    );
  }

  @override
  Widget body(BuildContext context) {
    const double _iconSize = 24;
    const double _iconOffset = 12;
    return Observer(builder: (_) {
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (contactViewModel.manual.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: ContactAddressesExpansionTile(
                    key: ValueKey(contactViewModel.name),
                    title: Text('Manual Addresses'),
                    initiallyExpanded: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainer,
                    addressByCurrency: contactViewModel.manual,
                    onCopyPressed: (address) async =>
                        await Clipboard.setData(ClipboardData(text: address)),
                    onEditPressed: (cur, lbl) {
                      Navigator.pushNamed(
                        context,
                        Routes.editAddressPage,
                        arguments: [contactViewModel, cur, lbl],
                      );
                    },
                  ),
                ),
              ...contactViewModel.parsedBlocks.entries.map((entry) {
                final handleKey = entry.key;
                final srcLabel = handleKey.split('-').first;
                final byCurrency = entry.value;
                final src = AddressSourceNameParser.fromLabel(srcLabel);

                final currencies = byCurrency.keys.toList();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 8),
                        ImageUtil.getImageFromPath(
                          imagePath: src.iconPath,
                          height: 24,
                          width: 24,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            handleKey,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                        contactViewModel.state is IsExecutingState
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : SizedBox(
                                width: _iconSize + _iconOffset * (currencies.length - 1),
                                height: _iconSize,
                                child: Stack(
                                  children: [
                                    for (int i = 0; i < currencies.length; ++i)
                                      Positioned(
                                        left: i * _iconOffset,
                                        child: CircleAvatar(
                                          radius: _iconSize / 2,
                                          backgroundColor: Colors.transparent,
                                          child: ImageUtil.getImageFromPath(
                                            imagePath: currencies[i].iconPath ?? '',
                                            height: _iconSize - 4,
                                            width: _iconSize - 4,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                        const SizedBox(width: 8),
                        RoundedIconButton(
                          icon: Icons.edit,
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              Routes.editAliasPage,
                              arguments: [contactViewModel, handleKey],
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      );
    });
  }
}
