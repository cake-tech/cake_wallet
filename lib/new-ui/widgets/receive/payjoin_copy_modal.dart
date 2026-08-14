import "package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/receive/receive_top_bar.dart";
import "package:cake_wallet/src/widgets/new_list_row/new_list_section.dart";
import "package:cake_wallet/utils/clipboard_util.dart";
import "package:cw_core/payment_uris.dart";
import "package:flutter/material.dart";
import "package:flutter/semantics.dart";
import "package:flutter/services.dart";

class PayjoinCopyModal extends StatelessWidget {
  const PayjoinCopyModal({
    required this.uri,
    super.key,
  });

  final PaymentURI uri;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          color: Theme.of(context).colorScheme.surface,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ModalTopBar(
                title: S.of(context).select_address_to_copy,
                leadingIcon: const Icon(Icons.close),
                leadingSemanticLabel: S.of(context).close,
                onLeadingPressed: Navigator.of(context).pop,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: NewListSections(
                  sections: {
                    "": [
                      ListItemRegularRow(
                        keyValue: "btc",
                        label: S.of(context).standard,
                        iconPath: "assets/new-ui/pjmodal_btc.svg",
                        onTap: () {
                          ClipboardUtil.setSensitiveDataToClipboard(
                            ClipboardData(
                              text: uri.amount.isNotEmpty
                                  ? BitcoinURI(amount: uri.amount, address: uri.address).toString()
                                  : uri.address,
                            ),
                            isSensitive: true,
                          );
                          _announceCopied(context);
                          Navigator.of(context).pop();
                        },
                      ),
                      ListItemRegularRow(
                        keyValue: "pj",
                        label: "Payjoin",
                        iconPath: "assets/new-ui/pjmodal_pj.svg",
                        onTap: () {
                          ClipboardUtil.setSensitiveDataToClipboard(
                            ClipboardData(text: uri.toString()),
                            isSensitive: true,
                          );
                          _announceCopied(context);
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  },
                ),
              ),
              const SizedBox(height: 128),
            ],
          ),
        ),
      );

  // Copying pops this sheet right away, so no widget survives to carry a
  // semantics state change: this path still needs a direct announcement. It is
  // skipped on platforms that deprecate announcements (android, where they
  // clear TalkBack's speech queue and the system shows its own clipboard
  // confirmation anyway).
  void _announceCopied(BuildContext context) {
    if (!MediaQuery.supportsAnnounceOf(context)) {
      return;
    }
    SemanticsService.sendAnnouncement(
      View.of(context),
      S.of(context).copied,
      Directionality.of(context),
    );
  }
}
