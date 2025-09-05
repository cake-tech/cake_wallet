import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/address_resolver/parsed_address.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/address_book/sheet_page.dart';
import 'package:cake_wallet/src/screens/address_book/widgets/addresses_expansion_tile_widget.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/utils/image_utill.dart';
import 'package:cake_wallet/view_model/contact_list/contact_view_model.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class ContactRefreshPage extends SheetPage {
  ContactRefreshPage({required this.currency, required this.contactViewModel}) {
    contactViewModel.refresh();
  }

  final CryptoCurrency currency;
  final ContactViewModel contactViewModel;

  @override
  Widget middle(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child:
                  Image(image: contactViewModel.avatar, width: 24, height: 24, fit: BoxFit.cover)),
          const SizedBox(width: 12),
          Text(contactViewModel.name,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis)
        ],
      );

  @override
  Widget body(BuildContext context) {
    return Observer(builder: (_) {
      if (contactViewModel.state is IsExecutingState) {
        return const _ProgressCard();
      }

      final hasCurrency =
          contactViewModel.parsedBlocks.values.any((m) => m[currency]?.isNotEmpty == true) ||
              contactViewModel.manual[currency]?.isNotEmpty == true;

      if (!hasCurrency) {
        return _ErrorCard(currency: currency);
      }

      return _FilteredAddressesCard(
        contactViewModel: contactViewModel,
        currency: currency,
      );
    });
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard();

  @override
  Widget build(BuildContext context) => SizedBox(
        height: MediaQuery.of(context).size.height * .35,
        width: double.infinity,
        child: Column(
          children: [
            const Spacer(),
            Text(
              S.of(context).checking_for_alias_changes,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const Spacer(flex: 2),
            const SizedBox(width: 60, height: 60, child: CircularProgressIndicator()),
            const Spacer(flex: 3),
          ],
        ),
      );
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.currency});

  final CryptoCurrency currency;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: MediaQuery.of(context).size.height * .35,
        child: Column(
          children: [
            Spacer(),
            Text(S.of(context).error, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                S.of(context).contact_no_longer_has_an_address_assigne,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),
            Spacer(flex: 2),
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              child: LoadingPrimaryButton(
                text: S.of(context).ok,
                width: 150,
                height: 40,
                color: Theme.of(context).colorScheme.primary,
                textColor: Theme.of(context).colorScheme.onPrimary,
                isLoading: false,
                isDisabled: false,
                onPressed: () {
                  if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
                },
              ),
            ),
          ],
        ),
      );
}

class _FilteredAddressesCard extends StatelessWidget {
  const _FilteredAddressesCard({
    required this.contactViewModel,
    required this.currency,
  });

  final ContactViewModel contactViewModel;
  final CryptoCurrency currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Observer(builder: (_) {
      final tiles = <Widget>[];

      final manualMap = contactViewModel.manual[currency];
      if (manualMap != null && manualMap.isNotEmpty) {
        tiles.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ContactAddressesExpansionTile(
              key: ValueKey('${contactViewModel.name}-manual-$currency'),
              title: const Text('Manual Addresses'),
              initiallyExpanded: true,
              shouldTruncateContent: false,
              fillColor: theme.colorScheme.surfaceContainer,
              addressByCurrency: {currency: manualMap},
              onAddressPressed: (address) {
                if (context.mounted)
                  Navigator.of(context, rootNavigator: true)
                      .pop((contactViewModel.record, address));
              },
            ),
          ),
        );
      }

      contactViewModel.parsedBlocks.forEach((handle, byCurrency) {
        final curMap = byCurrency[currency];
        if (curMap == null || curMap.isEmpty) return;
        final srcLabel = handle.split('-').first;
        final src = AddressSourceNameParser.fromLabel(srcLabel);

        tiles.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ContactAddressesExpansionTile(
              key: ValueKey('${contactViewModel.name}-$handle-$currency'),
              initiallyExpanded: true,
              shouldTruncateContent: false,
              fillColor: theme.colorScheme.surfaceContainer,
              addressByCurrency: {currency: curMap},
              onAddressPressed: (address) {
                if (context.mounted)
                  Navigator.of(context, rootNavigator: true)
                      .pop((contactViewModel.record, address));
              },
              title: Row(
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
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      });
      tiles.add(const SizedBox(height: 16));

      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: tiles,
        ),
      );
    });
  }
}
