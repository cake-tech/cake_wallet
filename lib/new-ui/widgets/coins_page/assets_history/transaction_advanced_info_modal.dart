import "package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/src/screens/transaction_details/confirmations_list_item.dart";
import "package:cake_wallet/src/widgets/fee_fetch_progress_indicator.dart";
import "package:cake_wallet/src/widgets/new_list_row/new_list_section.dart";
import "package:cake_wallet/utils/address_formatter.dart";
import "package:cake_wallet/view_model/transaction_details_view_model.dart";
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
                        _TransactionAdvancedInfoItemsSection(
                          transactionDetailsViewModel: transactionDetailsViewModel,
                        ),
                        if (transactionDetailsViewModel.hasAddressBreakdown)
                          _AddressBreakdownSections(
                            transactionDetailsViewModel: transactionDetailsViewModel,
                          ),
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

class _TransactionAdvancedInfoItemsSection extends StatelessWidget {
  const _TransactionAdvancedInfoItemsSection({required this.transactionDetailsViewModel});

  final TransactionDetailsViewModel transactionDetailsViewModel;

  @override
  Widget build(BuildContext context) => Observer(
        builder: (_) => NewListSections(
          sections: {
            "": transactionDetailsViewModel.advancedItems
                .where((item) => item.value.isNotEmpty)
                .map((item) {
              final keyValue = ((item.key as ValueKey?)?.value as String?) ?? item.title;
              final isAdvancedFeeRow =
                  keyValue == "standard_list_item_transaction_details_advanced_fee_key";
              // "N/0" when the coin has no required-confirmations threshold: show just N.
              final value = item is ConfirmationsListItem && item.needed == 0
                  ? item.current.toString()
                  : item.value;
              final shouldBuildBottomWidget = value.length > 25;

              return ListItemRegularRow(
                copyableText: value,
                showArrow: false,
                keyValue: keyValue,
                label: item.title,
                trailingWidget: shouldBuildBottomWidget
                    ? null
                    : _TransactionAdvancedInfoRowTrailing(
                        transactionDetailsViewModel: transactionDetailsViewModel,
                        value: value,
                        isAdvancedFeeRow: isAdvancedFeeRow,
                      ),
                bottomWidget: shouldBuildBottomWidget
                    ? Text(
                        value,
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
      );
}

class _TransactionAdvancedInfoRowTrailing extends StatelessWidget {
  const _TransactionAdvancedInfoRowTrailing({
    required this.transactionDetailsViewModel,
    required this.value,
    required this.isAdvancedFeeRow,
  });

  final TransactionDetailsViewModel transactionDetailsViewModel;
  final String value;
  final bool isAdvancedFeeRow;

  // Nested Observer: isFetchingFee/feeFetch*/feeFiatAmount change on every
  // fee-fetch progress tick - reading them here instead of in the section's
  // outer Observer keeps those ticks from re-running its entire
  // advancedItems.map() on every single chunk.
  @override
  Widget build(BuildContext context) => Observer(
        builder: (_) {
          final isLoadingFee = isAdvancedFeeRow && transactionDetailsViewModel.isFetchingFee;
          final fiatAmount = transactionDetailsViewModel.feeFiatAmount;
          if (isLoadingFee) {
            return FeeFetchProgressIndicator(
              resolved: transactionDetailsViewModel.feeFetchResolvedInputs,
              total: transactionDetailsViewModel.feeFetchTotalInputs,
            );
          }
          if (isAdvancedFeeRow && fiatAmount.isNotEmpty) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(value),
                const SizedBox(height: 2),
                Text(
                  fiatAmount,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            );
          }
          return Text(value);
        },
      );
}

/// "Coins spent" and "Change"/"Received coins" breakdown sections.
class _AddressBreakdownSections extends StatelessWidget {
  const _AddressBreakdownSections({required this.transactionDetailsViewModel});

  final TransactionDetailsViewModel transactionDetailsViewModel;

  @override
  Widget build(BuildContext context) {
    final vm = transactionDetailsViewModel;
    final spent = vm.addressBreakdown.where((entry) => !entry.isOutput).toList();
    final change =
        vm.addressBreakdown.where((entry) => entry.isOutput && entry.isChangeAddress).toList();
    final received =
        vm.addressBreakdown.where((entry) => entry.isOutput && !entry.isChangeAddress).toList();

    return Column(
      spacing: 12,
      children: [
        if (spent.isNotEmpty)
          _AddressBreakdownSection(
            title: spent.length > 1 ? S.of(context).coins_spent : S.of(context).coin_spent,
            rowLabel: S.of(context).spent,
            entries: spent,
            walletType: vm.wallet.type,
            total: vm.formatAddressBreakdownTotal(spent),
          ),
        if (received.isNotEmpty)
          _AddressBreakdownSection(
            title: S.of(context).received_coins,
            rowLabel: S.of(context).received,
            entries: received,
            walletType: vm.wallet.type,
            total: vm.formatAddressBreakdownTotal(received),
          ),
        if (change.isNotEmpty)
          _AddressBreakdownSection(
            title: S.of(context).change,
            rowLabel: S.of(context).change,
            entries: change,
            walletType: vm.wallet.type,
            total: vm.formatAddressBreakdownTotal(change),
          ),
      ],
    );
  }
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
                  if (entry.isOutput && entry.isUnspent != null)
                    _AddressSpendableBadge(isUnspent: entry.isUnspent == true),
                ],
              ),
            ],
          ),
        ),
      );
}

class _AddressSpendableBadge extends StatelessWidget {
  const _AddressSpendableBadge({required this.isUnspent});

  final bool isUnspent;

  @override
  Widget build(BuildContext context) {
    final color = isUnspent ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isUnspent ? Icons.check_circle : Icons.cancel, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            isUnspent ? S.of(context).still_spendable : S.of(context).spent,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}
