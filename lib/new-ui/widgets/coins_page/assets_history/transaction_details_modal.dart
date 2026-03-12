import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item.dart';
import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/src/screens/transaction_details/confirmations_list_item.dart';
import 'package:cake_wallet/src/screens/transaction_details/transaction_details_list_item.dart';
import 'package:cake_wallet/src/screens/transaction_details/address_list_item.dart';
import 'package:cake_wallet/src/widgets/new_list_row/new_list_section.dart';
import 'package:cake_wallet/utils/address_formatter.dart';
import 'package:cake_wallet/view_model/transaction_details_view_model.dart';
import 'package:flutter/material.dart';

class TransactionDetailsModal extends StatefulWidget {
  const TransactionDetailsModal({super.key, required this.transactionDetailsViewModel});

  final TransactionDetailsViewModel transactionDetailsViewModel;

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
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.25,
        maxChildSize: 1.0,
        snap: true,
        snapSizes: const [0.6, 1.0],
        builder: (context, controller) => SafeArea(
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
                                Column(
                                  children: [
                                    Image.asset(
                                        widget.transactionDetailsViewModel.transactionAsset
                                                .iconPath ??
                                            "",
                                        width: 64,
                                        height: 64),
                                    SizedBox(height: 10),
                                    Text(
                                      widget.transactionDetailsViewModel.formattedTitle +
                                          widget.transactionDetailsViewModel.formattedStatus,
                                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      widget.transactionDetailsViewModel.transactionInfo
                                          .amountFormatted(),
                                      style: TextStyle(fontSize: 28),
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
                                                      showArrow: false,
                                                      keyValue: ((item.key as ValueKey?)?.value
                                                              as String?) ??
                                                          item.title,
                                                      label: item.title,
                                                      trailingWidget: shouldBuildBottomWidget
                                                          ? null
                                                          : _buildTrailingWIdget(item),
                                                      bottomWidget: shouldBuildBottomWidget
                                                          ?  _buildBottomWidget(item)
                                                          : null);
                                                })
                                                .whereType<ListItem>()
                                                .toList(),
                                          }),
                                          Container(
                                            decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(20),
                                                color:
                                                    Theme.of(context).colorScheme.surfaceContainer),
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
                                          NewListSections(sections: {
                                            "view tx": [
                                              ListItemRegularRow(
                                                  keyValue: "view tx on",
                                                  label: widget.transactionDetailsViewModel
                                                      .explorerDescription,
                                                  onTap: widget
                                                      .transactionDetailsViewModel.launchExplorer)
                                            ]
                                          })
                                        ],
                                      ),
                                    )
                                  ],
                                )
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

  Widget _buildTrailingWIdget(TransactionDetailsListItem item) {
    return switch (item.runtimeType) {
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
    };
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
