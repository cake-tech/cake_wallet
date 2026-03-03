import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/src/widgets/new_list_row/new_list_section.dart';
import 'package:cw_core/payment_uris.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PayjoinCopyModal extends StatelessWidget {
  const PayjoinCopyModal({super.key, required this.uri});

  final PaymentURI uri;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          color: Theme.of(context).colorScheme.surface),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ModalTopBar(
                title: S.of(context).select_address_to_copy,
                leadingIcon: Icon(Icons.close),
                onLeadingPressed: Navigator.of(context).pop),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: NewListSections(sections: {
                "": [
                  ListItemRegularRow(
                      keyValue: "btc",
                      label: "Standard",
                      iconPath: "assets/new-ui/pjmodal_btc.svg",
                      onTap: () {
                        Clipboard.setData(
                          ClipboardData(
                              text: uri.amount.isNotEmpty
                                  ? BitcoinURI(amount: uri.amount, address: uri.address).toString()
                                  : uri.address),
                        );
                        Navigator.of(context).pop();
                      }),
                  ListItemRegularRow(
                      keyValue: "pj",
                      label: "Payjoin",
                      iconPath: "assets/new-ui/pjmodal_pj.svg",
                      onTap: () {
                        Clipboard.setData(
                          ClipboardData(text: uri.toString()),
                        );
                        Navigator.of(context).pop();
                      })
                ]
              }),
            ),
            SizedBox(height:128)
          ],
        ),
      ),
    );
  }
}
