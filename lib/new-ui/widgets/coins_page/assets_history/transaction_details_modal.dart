import "package:cake_wallet/entities/new_ui_entities/list_item/list_item.dart";
import "package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/coins_page/token_image_widget.dart";
import "package:cake_wallet/new-ui/widgets/copy_wrapper.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/routes.dart";
import "package:cake_wallet/src/screens/transaction_details/address_list_item.dart";
import "package:cake_wallet/src/screens/transaction_details/confirmations_list_item.dart";
import "package:cake_wallet/src/screens/transaction_details/transaction_details_list_item.dart";
import "package:cake_wallet/src/widgets/new_list_row/new_list_section.dart";
import "package:cake_wallet/utils/address_formatter.dart";
import "package:cake_wallet/view_model/transaction_details_view_model.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_mobx/flutter_mobx.dart";
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";

class TransactionDetailsModal extends StatefulWidget {
  const TransactionDetailsModal(
      {
    required this.transactionDetailsViewModel,
    this.highlightNoteField = false,
    super.key,
  });

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

    if (widget.highlightNoteField) {
      noteFocusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: GestureDetector(
            onTap: FocusScope.of(context).unfocus,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: Column(
                children: [
                  ModalTopBar(
                    title: S.of(context).transaction,
                    leadingIcon: const Icon(Icons.close),
                    leadingSemanticLabel: S.of(context).close,
                    onLeadingPressed: Navigator.of(context).pop,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: ModalScrollController.of(context),
                      child: Column(
                        children: [
                          TokenImageWidget(
                            imageUrl:
                                widget.transactionDetailsViewModel.transactionAsset.iconPath ?? "",
                            size: 64,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            widget.transactionDetailsViewModel.formattedTitle +
                                widget.transactionDetailsViewModel.formattedStatus,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                          ),
                          Observer(
                            builder: (_) => CopyWrapper(
                              requireLongPress: true,
                              data: ClipboardData(
                                text: widget.transactionDetailsViewModel.transactionCopyAmount,
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
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              spacing: 12,
                              children: [
                                NewListSections(
                                  sections: {
                                    "": widget.transactionDetailsViewModel.items
                                        .map((item) {
                                          if (item.value.isEmpty) {
                                            return null;
                                          }

                                          final shouldBuildBottomWidget = item.value.length > 25;

                                          return ListItemRegularRow(
                                            copyableText: item.value,
                                            showArrow: false,
                                            keyValue: ((item.key as ValueKey?)?.value as String?) ??
                                                item.title,
                                            label: item.title,
                                            trailingWidget: shouldBuildBottomWidget
                                                ? null
                                                : _buildTrailingWidget(item),
                                            bottomWidget: shouldBuildBottomWidget
                                                ? _buildBottomWidget(item)
                                                : null,
                                          );
                                        })
                                        .whereType<ListItem>()
                                        .toList(),
                                  },
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: Theme.of(context).colorScheme.surfaceContainer,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
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
                                            isDense: true,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Observer(
                                  builder: (_) => NewListSections(
                                    sections: {
                                      "view tx": [
                                        ListItemRegularRow(
                                          keyValue: "view tx on",
                                          label: widget
                                              .transactionDetailsViewModel.explorerDescription,
                                          onTap: widget.transactionDetailsViewModel.launchExplorer,
                                          foregroundColor: Theme.of(context).colorScheme.primary,
                                          trailingIconPath: "assets/new-ui/link_arrow.svg",
                                          trailingIconSize: 8,
                                        ),
                                      ],
                                      if (widget.transactionDetailsViewModel.canReplaceByFee)
                                        "rbf": [
                                          ListItemRegularRow(
                                            keyValue: "replace by fee",
                                            label: S.of(context).bump_fee,
                                            onTap: () {
                                              Navigator.of(context).pushNamed(
                                                Routes.bumpFeePage,
                                                arguments: [
                                                  widget
                                                      .transactionDetailsViewModel.transactionInfo,
                                                  widget.transactionDetailsViewModel.rawTransaction,
                                                ],
                                              );
                                            },
                                          ),
                                        ],
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _buildTrailingWidget(TransactionDetailsListItem item) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: switch (item.runtimeType) {
          ConfirmationsListItem => Row(
              children: [
                Text(
                  (item as ConfirmationsListItem).current.toString(),
                  style: TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
                if (item.needed > 0)
                  Text(
                    "/${item.needed}",
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
              ],
            ),
          _ => Text(
              item.value,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            )
        },
      );

  Widget _buildBottomWidget(TransactionDetailsListItem item) {
    return switch (item.runtimeType) {
      AddressListItem => _segmentedAddressList(item.value),
      _ => Text(
          item.value,
          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
        )
    };
  }

  Widget _segmentedAddressList(String value) {
    final style = TextStyle(
      fontSize: 12,
      fontFamily: "IBM Plex Mono",
      color: Theme.of(context).colorScheme.onSurface,
    );
    final lines = value
        .split(RegExp(r'[,\n]'))
        .map((final line) => line.trim())
        .where((final line) => line.isNotEmpty)
        .toList();
    if (lines.length <= 1) {
      return AddressFormatter.buildSegmentedAddress(
        address: lines.isNotEmpty ? lines.first : value.trim(),
        evenTextStyle: style,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in lines)
          AddressFormatter.buildSegmentedAddress(address: line, evenTextStyle: style),
      ],
    );
  }
}
