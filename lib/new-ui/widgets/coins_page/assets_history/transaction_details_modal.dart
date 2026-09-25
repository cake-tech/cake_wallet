import "package:cake_wallet/entities/new_ui_entities/list_item/list_item.dart";
import "package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/coins_page/token_image_widget.dart";
import "package:cake_wallet/new-ui/widgets/copy_wrapper.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/routes.dart";
import "package:cake_wallet/new-ui/widgets/coins_page/assets_history/transaction_advanced_info_modal.dart";
import "package:cake_wallet/src/screens/transaction_details/address_list_item.dart";
import "package:cake_wallet/src/screens/transaction_details/confirmations_list_item.dart";
import "package:cake_wallet/src/screens/transaction_details/transaction_details_list_item.dart";
import "package:cake_wallet/src/widgets/fee_fetch_progress_indicator.dart";
import "package:cake_wallet/src/widgets/new_list_row/new_list_section.dart";
import "package:cake_wallet/utils/address_formatter.dart";
import "package:cake_wallet/view_model/transaction_details_view_model.dart";
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
                            builder: (context) {
                              final vm = widget.transactionDetailsViewModel;
                              // isAmountPending is only true for a partially-owned
                              // send (see fromElectrumBundle) - reading
                              // isFetchingFee/feeFetchFailed here (the same
                              // observables the fee row reacts to) is what makes
                              // this rebuild once resolution actually progresses,
                              // since transactionInfo.amount itself isn't observable.
                              if (vm.isAmountPending) {
                                if (vm.isFetchingFee) {
                                  return FeeFetchProgressIndicator(
                                    resolved: vm.feeFetchResolvedInputs,
                                    total: vm.feeFetchTotalInputs,
                                    diameter: 40,
                                  );
                                }
                                if (vm.feeFetchFailed) {
                                  return Text(
                                    "…",
                                    style: TextStyle(
                                      fontSize: 28,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  );
                                }
                              }
                              return CopyWrapper(
                                requireLongPress: true,
                                data: ClipboardData(text: vm.transactionCopyAmount),
                                builder: (context, copied) => AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: Text(
                                    key: ValueKey(copied),
                                    copied ? S.of(context).copied : vm.transactionAmount,
                                    style: TextStyle(
                                      fontSize: 28,
                                      color: copied
                                          ? Theme.of(context).colorScheme.primary
                                          : Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          if (widget.transactionDetailsViewModel.transactionFiatAmount.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                widget.transactionDetailsViewModel.transactionFiatAmount,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              spacing: 12,
                              children: [
                                Observer(
                                  builder: (_) => NewListSections(
                                    sections: {
                                      "": widget.transactionDetailsViewModel.items
                                          .map((item) {
                                            if (item.value.isEmpty) {
                                              return null;
                                            }

                                            final shouldBuildBottomWidget = item.value.length > 25;
                                            final keyValue =
                                                ((item.key as ValueKey?)?.value as String?) ??
                                                    item.title;

                                            return ListItemRegularRow(
                                              copyableText: item.value,
                                              showArrow: false,
                                              keyValue: keyValue,
                                              label: _isFeeRow(item)
                                                  ? widget.transactionDetailsViewModel.feeTitle
                                                  : item.title,
                                              trailingWidget: shouldBuildBottomWidget
                                                  ? null
                                                  // Nested Observer: isFetchingFee/feeFetch*
                                                  // change on every fee-fetch progress tick.
                                                  // Reading them here instead of in the outer
                                                  // Observer keeps those ticks from also
                                                  // re-running _buildSendBreakdownRows() (an
                                                  // O(all wallet transactions) scan) on every
                                                  // single chunk.
                                                  : Observer(
                                                      builder: (_) => _buildTrailingWidget(item),
                                                    ),
                                              bottomWidget: shouldBuildBottomWidget
                                                  ? _buildBottomWidget(item)
                                                  : null,
                                            );
                                          })
                                          .whereType<ListItem>()
                                          .toList()
                                        ..addAll(_buildSendBreakdownRows()),
                                    },
                                  ),
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
                                      if (widget.transactionDetailsViewModel.hasAdvancedInfo)
                                        "advanced": [
                                          ListItemRegularRow(
                                            keyValue: "advanced info",
                                            label: S.of(context).advanced_info,
                                            onTap: () {
                                              widget.transactionDetailsViewModel
                                                  .ensureFeeResolutionWatched();
                                              showModalBottomSheet<void>(
                                                context: context,
                                                isScrollControlled: true,
                                                backgroundColor: Colors.transparent,
                                                // Matches the heightFactor cap this transaction
                                                // details modal itself is shown with (see
                                                // history_section.dart) - without it this sheet
                                                // has nothing capping its height, so it grows all
                                                // the way to the top of the screen.
                                                builder: (_) => FractionallySizedBox(
                                                  heightFactor: 0.9,
                                                  child: TransactionAdvancedInfoModal(
                                                    transactionDetailsViewModel:
                                                        widget.transactionDetailsViewModel,
                                                  ),
                                                ),
                                              );
                                            },
                                            trailingIconPath: "assets/new-ui/link_arrow.svg",
                                            trailingIconSize: 8,
                                          ),
                                        ],
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
          _ => _isFeeRow(item) && widget.transactionDetailsViewModel.isFetchingFee
              ? FeeFetchProgressIndicator(
                  resolved: widget.transactionDetailsViewModel.feeFetchResolvedInputs,
                  total: widget.transactionDetailsViewModel.feeFetchTotalInputs,
                )
              : _isFeeRow(item) && widget.transactionDetailsViewModel.feeFiatAmount.isNotEmpty
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          item.value,
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.transactionDetailsViewModel.feeFiatAmount,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      item.value,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    )
        },
      );

  bool _isFeeRow(TransactionDetailsListItem item) =>
      (item.key as ValueKey?)?.value == "standard_list_item_transaction_details_fee_key";

  List<ListItem> _buildSendBreakdownRows() {
    final vm = widget.transactionDetailsViewModel;
    if (!vm.isConfidentSend || vm.totalSentAmount.isEmpty) {
      return [];
    }

    final rows = <ListItem>[];

    // "Total paid" (amount + fee) needs a known fee for this wallet's share.
    // For a co-spend/consolidation transaction (see hasForeignInputs) that
    // share can't be known for certain, and the fee row itself is hidden.
    if (!vm.hasForeignInputs) {
      rows.add(
        ListItemRegularRow(
          keyValue: "standard_list_item_transaction_details_total_sent_key",
          showArrow: false,
          label: S.of(context).total_paid,
          trailingWidget: _buildAmountFiatColumn(
            vm.totalSentAmount,
            vm.totalSentFiatAmount,
          ),
        ),
      );
    }

    if (vm.changeReceivedAmount.isNotEmpty) {
      rows.add(
        ListItemRegularRow(
          keyValue: "standard_list_item_transaction_details_change_received_key",
          showArrow: false,
          label: S.of(context).change_received,
          trailingWidget: _buildAmountFiatColumn(
            vm.changeReceivedAmount,
            vm.changeReceivedFiatAmount,
          ),
        ),
      );
    }

    return rows;
  }

  Widget _buildAmountFiatColumn(String amount, String fiatAmount) => Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            amount,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          if (fiatAmount.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              fiatAmount,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
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
