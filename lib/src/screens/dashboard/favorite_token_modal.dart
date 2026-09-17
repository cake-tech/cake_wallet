import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/src/widgets/new_list_row/new_list_section.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:flutter/material.dart';

class FavoriteTokenModal extends StatelessWidget {
  const FavoriteTokenModal({super.key, required this.tokens});

  final List<CryptoCurrency> tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      child: SafeArea(
        child: Column(
          children: [
            ModalTopBar(
              title: S.of(context).favorite_token,
              leadingIcon: Icon(Icons.close),
              leadingSemanticLabel: S.of(context).close,
              onLeadingPressed: Navigator.of(context).pop,
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    S.of(context).favorite_token_desc,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: SingleChildScrollView(
                        child: NewListSections(
                          sections: {
                            "": tokens
                                .map((item) => ListItemRegularRow(
                                    keyValue: item.title,
                                    label: "${item.fullName} (${item.title})",
                                    iconPath: item.iconPath,
                                    onTap: () => Navigator.of(context).pop(item)))
                                .toList()
                          },
                        ),
                      ),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
