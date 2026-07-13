import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item.dart';
import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/token_image_widget.dart';
import 'package:cake_wallet/new-ui/widgets/copy_wrapper.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/transaction_details/confirmations_list_item.dart';
import 'package:cake_wallet/src/screens/transaction_details/transaction_details_list_item.dart';
import 'package:cake_wallet/src/screens/transaction_details/address_list_item.dart';
import 'package:cake_wallet/src/widgets/new_list_row/new_list_section.dart';
import 'package:cake_wallet/utils/address_formatter.dart';
import 'package:cake_wallet/view_model/transaction_details_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class TransactionDetailsModal extends StatefulWidget {
  const TransactionDetailsModal({super.key, required this.transactionDetailsViewModel, this.highlightNoteField = false});

  final TransactionDetailsViewModel transactionDetailsViewModel;
  final bool highlightNoteField;

  @override
  State<TransactionDetailsModal> createState() => _TransactionDetailsModalState();
}

class _TransactionDetailsModalState extends State<TransactionDetailsModal> {
  final TextEditingController noteController = TextEditingController();
  final FocusNode noteFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    noteController.text = widget.transactionDetailsViewModel.note;

    noteFocusNode.addListener(() {
      if (!noteFocusNode.hasFocus) {
        widget.transactionDetailsViewModel.updateNote(noteController.text);
      }
    });

    if(widget.highlightNoteField) {
      noteFocusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        minChildSize: 0.25,
        maxChildSize: 0.9,
        snap: true,
        snapSizes: const [0.9],
        builder: (context, controller) => SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                child: GestureDetector(
                  onTap: FocusScope.of(context).unfocus,
                  child: Container(
                    decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
                    child: Column(
                      children: [
                        ModalTopBar(
                          title: S.of(context).transaction,
                          leadingIcon: Icon(Icons.close),
                          onLeadingPressed: Navigator.of(context).pop,
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            controller: controller,
                            child: Column(
                              children: [
                                TokenImageWidget(
                                  imageUrl: widget
                                          .transactionDetailsViewModel.transactionAsset.iconPath ??
                                      "",
                                  size: 64,
                                ),
                                SizedBox(height: 10),
                                Text(
                                  widget.transactionDetailsViewModel.formattedTitle +
                                      widget.transactionDetailsViewModel.formattedStatus,
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                                ),
                                Observer(
                                  builder: (_) => CopyWrapper(
                                    requireLongPress: true,
                                    data: ClipboardData(
                                      text:
                                          widget.transactionDetailsViewModel.transactionCopyAmount,
                                    ),
                                    builder: (context, copied) => AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 300),
                                      child: Text(
                                        key: ValueKey(copied),
                                        copied
                                            ? S.of(context).copied
                                            : widget.transactionDetailsViewModel.transactionAmount,
                                        style: TextStyle(
                                          fontSize: 28,
                                          color: copied
                                              ? Theme.of(context).colorScheme.primary
                                              : Theme.of(context).colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    spacing: 12,
                                    children: [
                                      NewListSections(sections: {
                                        "": widget.transactionDetailsViewModel.items
                                            .map((item) {
                                              if (item.value.isEmpty) return null;

                                              final shouldBuildBottomWidget =
                                                  item.value.length > 25;

                                              return ListItemRegularRow(
                                                copyableText: item.value,
                                                  showArrow: false,
                                                  keyValue:
                                                      ((item.key as ValueKey?)?.value as String?) ??
                                                          item.title,
                                                  label: item.title,
                                                  trailingWidget: shouldBuildBottomWidget
                                                      ? null
                                                      : _buildTrailingWidget(item),
                                                  bottomWidget: shouldBuildBottomWidget
                                                      ? _buildBottomWidget(item)
                                                      : null);
                                            })
                                            .whereType<ListItem>()
                                            .toList(),
                                      }),
                                      Container(
                                        decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(20),
                                            color: Theme.of(context).colorScheme.surfaceContainer),
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Column(
                                            spacing: 8,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(S.of(context).note),
                                              TextField(
                                                focusNode: noteFocusNode,
                                                controller: noteController,
                                                decoration: InputDecoration(
                                                    hintText: S.of(context).add_a_note,
                                                    border: InputBorder.none,
                                                    focusedBorder: InputBorder.none,
                                                    enabledBorder: InputBorder.none,
                                                    contentPadding: EdgeInsets.zero,
                                                    isDense: true),
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                      Observer(
                                        builder: (_) => NewListSections(sections: {
                                          "view tx": [
                                            ListItemRegularRow(
                                                keyValue: "view tx on",
                                                label: widget.transactionDetailsViewModel
                                                    .explorerDescription,
                                                onTap: widget
                                                    .transactionDetailsViewModel.launchExplorer,
                                                foregroundColor:
                                                    Theme.of(context).colorScheme.primary,
                                                trailingIconPath: "assets/new-ui/link_arrow.svg",
                                                trailingIconSize: 8)
                                          ],
                                          if (widget.transactionDetailsViewModel.canReplaceByFee)
                                            "rbf": [
                                              ListItemRegularRow(
                                                  keyValue: "replace by fee",
                                                  label: S.of(context).bump_fee,
                                                  onTap: () {
                                                    Navigator.of(context)
                                                        .pushNamed(Routes.bumpFeePage, arguments: [
                                                      widget.transactionDetailsViewModel
                                                          .transactionInfo,
                                                      widget.transactionDetailsViewModel
                                                          .rawTransaction
                                                    ]);
                                                  })
                                            ]
                                        }),
                                      )
                                    ],
                                  ),
                                ),
                                SizedBox(height: MediaQuery.of(context).viewPadding.bottom)
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ));
  }

  Widget _buildTrailingWidget(TransactionDetailsListItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: switch (item.runtimeType) {
        ConfirmationsListItem => Row(
            children: [
              Text((item as ConfirmationsListItem).current.toString(),
                  style: TextStyle(color: Theme.of(context).colorScheme.primary)),
              if (item.needed > 0)
                Text("/${item.needed}",
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))
            ],
          ),
        _ => Text(
            item.value,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          )
      },
    );
  }

  Widget _buildBottomWidget(TransactionDetailsListItem item) {
    return switch (item.runtimeType) {
      AddressListItem => AddressFormatter.buildSegmentedAddress(
          address: item.value,
          evenTextStyle: TextStyle(
              fontSize: 12,
              fontFamily: "IBM Plex Mono",
              color: Theme.of(context).colorScheme.onSurface)),
      _ => Text(
          item.value,
          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
        )
    };
  }
}
