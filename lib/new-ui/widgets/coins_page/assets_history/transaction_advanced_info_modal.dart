import "package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/src/widgets/fee_fetch_progress_indicator.dart";
import "package:cake_wallet/src/widgets/new_list_row/new_list_section.dart";
import "package:cake_wallet/utils/address_formatter.dart";
import "package:cake_wallet/view_model/transaction_details_view_model.dart";
import "package:cw_core/transaction_direction.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/material.dart";
import "package:flutter_mobx/flutter_mobx.dart";
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";

class TransactionAdvancedInfoModal extends StatelessWidget {
  const TransactionAdvancedInfoModal({required this.transactionDetailsViewModel, super.key});

  final TransactionDetailsViewModel transactionDetailsViewModel;

  @override
  Widget build(BuildContext context) => SafeArea(
        bottom: false,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            children: [
              ModalTopBar(
                title: S.of(context).advanced_info,
                leadingIcon: const Icon(Icons.close),
                leadingSemanticLabel: S.of(context).close,
                onLeadingPressed: Navigator.of(context).pop,
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: ModalScrollController.of(context),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      spacing: 12,
                      children: [
                        Observer(
                          builder: (_) => NewListSections(
                            sections: {
                              "": transactionDetailsViewModel.advancedItems
                                  .where((item) => item.value.isNotEmpty)
                                  .map((item) {
                                final keyValue =
                                    ((item.key as ValueKey?)?.value as String?) ?? item.title;
                                final isAdvancedFeeRow = keyValue ==
                                    "standard_list_item_transaction_details_advanced_fee_key";
                                final shouldBuildBottomWidget = item.value.length > 25;
                                return ListItemRegularRow(
                                  copyableText: item.value,
                                  showArrow: false,
                                  keyValue: keyValue,
                                  label: item.title,
                                  // Nested Observer: isFetchingFee/feeFetch*/feeFiatAmount
                                  // change on every fee-fetch progress tick - reading them
                                  // here instead of in the outer Observer keeps those ticks
                                  // from re-running this entire advancedItems.map() on every
                                  // single chunk.
                                  trailingWidget: shouldBuildBottomWidget
                                      ? null
                                      : Observer(
                                          builder: (_) {
                                            final isLoadingFee = isAdvancedFeeRow &&
                                                transactionDetailsViewModel.isFetchingFee;
                                            final fiatAmount =
                                                transactionDetailsViewModel.feeFiatAmount;
                                            if (isLoadingFee) {
                                              return FeeFetchProgressIndicator(
                                                resolved: transactionDetailsViewModel
                                                    .feeFetchResolvedInputs,
                                                total:
                                                    transactionDetailsViewModel.feeFetchTotalInputs,
                                              );
                                            }
                                            if (isAdvancedFeeRow && fiatAmount.isNotEmpty) {
                                              return Column(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  Text(item.value),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    fiatAmount,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                    ),
                                                  ),
                                                ],
                                              );
                                            }
                                            return Text(item.value);
                                          },
                                        ),
                                  bottomWidget: shouldBuildBottomWidget
                                      ? Text(
                                          item.value,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          ),
                                        )
                                      : null,
                                );
                              }).toList(),
                            },
                          ),
                        ),
                        if (transactionDetailsViewModel.hasAddressBreakdown) ...[
                          if (transactionDetailsViewModel.addressBreakdown
                              .any((entry) => !entry.isChange))
                            _AddressBreakdownSection(
                              title: transactionDetailsViewModel.addressBreakdown
                                          .where((entry) => !entry.isChange)
                                          .length >
                                      1
                                  ? S.of(context).coins_spent
                                  : S.of(context).coin_spent,
                              rowLabel: S.of(context).spent,
                              entries: transactionDetailsViewModel.addressBreakdown
                                  .where((entry) => !entry.isChange)
                                  .toList(),
                              walletType: transactionDetailsViewModel.wallet.type,
                              total: transactionDetailsViewModel.formatAddressBreakdownTotal(
                                transactionDetailsViewModel.addressBreakdown
                                    .where((entry) => !entry.isChange)
                                    .toList(),
                              ),
                            ),
                          if (transactionDetailsViewModel.addressBreakdown
                              .any((entry) => entry.isChange))
                            _AddressBreakdownSection(
                              // Every owned output is recorded with isChange:
                              // true regardless of transaction direction - on
                              // an outgoing transaction that's genuinely
                              // change coming back to the wallet, but on an
                              // incoming one there's no "change" at all, just
                              // the coins actually received.
                              title: transactionDetailsViewModel.transactionInfo.direction ==
                                      TransactionDirection.incoming
                                  ? S.of(context).received_coins
                                  : S.of(context).change,
                              rowLabel: transactionDetailsViewModel.transactionInfo.direction ==
                                      TransactionDirection.incoming
                                  ? S.of(context).received
                                  : S.of(context).change,
                              entries: transactionDetailsViewModel.addressBreakdown
                                  .where((entry) => entry.isChange)
                                  .toList(),
                              walletType: transactionDetailsViewModel.wallet.type,
                              total: transactionDetailsViewModel.formatAddressBreakdownTotal(
                                transactionDetailsViewModel.addressBreakdown
                                    .where((entry) => entry.isChange)
                                    .toList(),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
            ],
          ),
        ),
      );
}

class _AddressBreakdownSection extends StatelessWidget {
  const _AddressBreakdownSection({
    required this.title,
    required this.rowLabel,
    required this.entries,
    required this.walletType,
    required this.total,
  });

  final String title;
  final String rowLabel;
  final List<TransactionAddressBreakdownItem> entries;
  final WalletType walletType;
  final String total;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style:
                    TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              Text(
                "${S.of(context).total}: $total",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0)
              Container(height: 1, color: Theme.of(context).colorScheme.surfaceContainerHigh),
            _AddressBreakdownRow(
              entry: entries[i],
              rowLabel: rowLabel,
              walletType: walletType,
              isFirst: i == 0,
              isLast: i == entries.length - 1,
            ),
          ],
        ],
      );
}

class _AddressBreakdownRow extends StatelessWidget {
  const _AddressBreakdownRow({
    required this.entry,
    required this.rowLabel,
    required this.walletType,
    required this.isFirst,
    required this.isLast,
  });

  final TransactionAddressBreakdownItem entry;
  final String rowLabel;
  final WalletType walletType;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(isFirst ? 16 : 0),
            bottom: Radius.circular(isLast ? 16 : 0),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              AddressFormatter.buildSegmentedAddress(
                address: entry.address,
                walletType: walletType,
                textAlign: TextAlign.left,
                evenTextStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${S.of(context).transactions}: ${entry.txCount ?? 0}",
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    "${S.of(context).balance}: ${entry.balanceDisplay ?? "—"}",
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "$rowLabel: ${entry.amount}",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  if (entry.isChange && entry.isUnspent != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color:
                            (entry.isUnspent == true ? Colors.green : Colors.red).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            entry.isUnspent == true ? Icons.check_circle : Icons.cancel,
                            size: 10,
                            color: entry.isUnspent == true ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            entry.isUnspent == true
                                ? S.of(context).still_spendable
                                : S.of(context).spent,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: entry.isUnspent == true ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
}
