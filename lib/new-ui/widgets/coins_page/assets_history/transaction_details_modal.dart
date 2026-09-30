import "package:cake_wallet/entities/new_ui_entities/list_item/list_item.dart";
import "package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart";
import "package:cake_wallet/utils/show_bar.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/coins_page/assets_history/conversion_timeline_card.dart";
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
import "package:cake_wallet/entities/conversion_display.dart";
import "package:cake_wallet/entities/conversion_status.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_mobx/flutter_mobx.dart";
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";

class TransactionDetailsModal extends StatefulWidget {
  const TransactionDetailsModal({
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

  ConversionDisplay? get _conversionDisplay => ConversionDisplayUtils.displayFrom(
      widget.transactionDetailsViewModel.transactionInfo.additionalInfo);

  bool _refunding = false;

  Future<void> _requestRefund() async {
    setState(() => _refunding = true);

    var requested = false;
    try {
      requested = await widget.transactionDetailsViewModel.requestConversionRefund();
    } catch (e) {
      printV("TransactionDetailsModal: refund request failed: $e");
    }

    if (!mounted) {
      return;
    }

    setState(() => _refunding = false);

    await showBar<void>(
      context,
      requested
          ? S.of(context).conversion_refund_requested
          : S.of(context).conversion_refund_request_failed,
    );
  }

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
                          Builder(builder: (context) {
                            final display = _conversionDisplay;
                            final paidFrom = ConversionDisplayUtils.paidFromLabel(
                                widget.transactionDetailsViewModel.transactionInfo.additionalInfo);
                            // A conversion is always framed as receiving the destination asset -
                            // never "Sent", even when this specific payment record's own
                            // direction is outgoing (e.g. the token side of a BTC -> token
                            // conversion, or a self-paid invoice's own bookkeeping).
                            final title = display != null
                                ? S.of(context).received
                                : widget.transactionDetailsViewModel.formattedTitle;
                            return Column(
                              children: [
                                Text(
                                  // A conversion's own "Converting to …" line below already says
                                  // it's pending.
                                  display != null
                                      ? title
                                      : title + widget.transactionDetailsViewModel.formattedStatus,
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                                ),
                                if (display == null && paidFrom != null)
                                  Text(
                                    S.of(context).stable_balance_send_paid_from(paidFrom),
                                    key: const ValueKey("transaction_details_paid_from"),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                if (display != null &&
                                    !ConversionDisplayUtils.needsAttention(display.status))
                                  Text(
                                    display.status == ConversionStatus.pending
                                        ? S.of(context).conversion_converting_to(display.toLabel)
                                        : S
                                            .of(context)
                                            .conversion_converted_from(display.fromLabel),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            );
                          }),
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
                                if (_conversionDisplay != null)
                                  Observer(builder: (_) {
                                    final vm = widget.transactionDetailsViewModel;
                                    return ConversionTimelineCard(
                                      display: _conversionDisplay!,
                                      paymentReceivedAt: vm.transactionInfo.date,
                                      onRequestRefund:
                                          vm.canRequestConversionRefund ? _requestRefund : null,
                                      refunding: _refunding,
                                    );
                                  }),
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
