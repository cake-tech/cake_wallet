import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item.dart';
import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/copy_wrapper.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/src/screens/transaction_details/address_list_item.dart';
import 'package:cake_wallet/src/screens/transaction_details/blockexplorer_list_item.dart';
import 'package:cake_wallet/src/screens/transaction_details/confirmations_list_item.dart';
import 'package:cake_wallet/src/screens/transaction_details/transaction_details_list_item.dart';
import 'package:cake_wallet/src/screens/trade_details/trade_details_list_card.dart';
import 'package:cake_wallet/src/screens/trade_details/trade_details_status_item.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/src/widgets/new_list_row/new_list_section.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/utils/address_formatter.dart';
import 'package:cake_wallet/utils/show_bar.dart';
import 'package:cake_wallet/view_model/payjoin_details_view_model.dart';
import 'package:cw_core/amount/money.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class PayjoinDetailsModal extends StatefulWidget {
  const PayjoinDetailsModal({super.key, required this.payjoinDetailsViewModel});

  final PayjoinDetailsViewModel payjoinDetailsViewModel;

  @override
  State<PayjoinDetailsModal> createState() => _PayjoinDetailsModalState();
}

class _PayjoinDetailsModalState extends State<PayjoinDetailsModal> {
  final TextEditingController noteController = TextEditingController();
  final FocusNode noteFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    noteController.text = widget.payjoinDetailsViewModel.transactionDetailsViewModel?.note ?? '';
    noteFocusNode.addListener(() {
      if (!noteFocusNode.hasFocus) {
        widget.payjoinDetailsViewModel.transactionDetailsViewModel?.updateNote(noteController.text);
      }
    });
  }

  @override
  void dispose() {
    noteController.dispose();
    noteFocusNode.dispose();
    widget.payjoinDetailsViewModel.listener.cancel();
    super.dispose();
  }

  Future<bool> _confirmCancel(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertWithTwoActions(
            alertTitle: 'Cancel Payjoin',
            alertContent: 'Are you sure you want to cancel this payjoin session?',
            leftButtonText: S.of(ctx).close,
            rightButtonText: S.of(ctx).cancel,
            actionLeftButton: () => Navigator.of(ctx).pop(false),
            actionRightButton: () => Navigator.of(ctx).pop(true),
          ),
        ) ??
        false;
  }

  Future<bool> _confirmFallback(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertWithTwoActions(
            alertTitle: 'Fallback Broadcast',
            alertContent: 'Broadcast the original transaction instead of the payjoin?',
            leftButtonText: S.of(ctx).cancel,
            rightButtonText: S.of(ctx).ok,
            actionLeftButton: () => Navigator.of(ctx).pop(false),
            actionRightButton: () => Navigator.of(ctx).pop(true),
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.payjoinDetailsViewModel;
    final session = vm.payjoinSession;
    final isOutgoing = session.isSenderSession;
    final amountDisplay = getIt
        .get<AppStore>()
        .amountParsingProxy
        .asDisplayStringWithSymbol(Money(session.amount, CryptoCurrency.btc));

    return SafeArea(
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
                    title: S.current.transaction,
                    leadingIcon: Icon(Icons.close),
                    onLeadingPressed: Navigator.of(context).pop,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: ModalScrollController.of(context),
                      child: Column(
                        children: [
                          Image.asset(
                            'assets/images/payjoin.png',
                            width: 64,
                            height: 64,
                          ),
                          SizedBox(height: 10),
                          Text(
                            "${isOutgoing ? S.of(context).outgoing : S.of(context).incoming} Payjoin",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                          ),
                          CopyWrapper(
                            requireLongPress: true,
                            data: ClipboardData(text: amountDisplay),
                            builder: (context, copied) => AnimatedSwitcher(
                              duration: Duration(milliseconds: 300),
                              child: Text(
                                key: ValueKey(copied),
                                copied ? S.of(context).copied : amountDisplay,
                                style: TextStyle(
                                    fontSize: 28,
                                    color: copied
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.onSurface),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Observer(
                              builder: (_) {
                                final items = vm.items
                                    .where((i) =>
                                        i is! DetailsListStatusItem &&
                                        i is! TradeDetailsListCardItem &&
                                        i is! BlockExplorerListItem)
                                    .whereType<TransactionDetailsListItem>()
                                    .toList();
                                final explorerItem =
                                    vm.items.whereType<BlockExplorerListItem>().firstOrNull;
                                return Column(
                                  spacing: 12,
                                  children: [
                                    NewListSections(sections: {
                                      "": items
                                          .map((item) {
                                            final shouldBuildBottomWidget = item.value.length > 25;
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
                                    if (vm.transactionDetailsViewModel != null)
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
                                    if (explorerItem != null)
                                      NewListSections(sections: {
                                        "view tx": [
                                          ListItemRegularRow(
                                            keyValue: "view tx on",
                                            label: explorerItem.title,
                                            onTap: explorerItem.onTap,
                                            foregroundColor: Theme.of(context).colorScheme.primary,
                                            trailingIconPath: "assets/new-ui/link_arrow.svg",
                                            trailingIconSize: 8,
                                          ),
                                        ],
                                      }),
                                    if (vm.canCancel || vm.canFallback) ...[
                                      if (vm.canCancel)
                                        _actionButton(
                                          context: context,
                                          label: 'Cancel',
                                          outlined: true,
                                          onPressed: () async {
                                            if (await _confirmCancel(context)) {
                                              vm.cancel();
                                              if (context.mounted) Navigator.of(context).pop();
                                            }
                                          },
                                        ),
                                      if (vm.canFallback)
                                        _actionButton(
                                          context: context,
                                          label: 'Fallback Broadcast',
                                          outlined: false,
                                          onPressed: () async {
                                            if (await _confirmFallback(context)) {
                                              try {
                                                await vm.fallbackBroadcast();
                                              } catch (e) {
                                                showBar<void>(context, 'Fallback failed: $e');
                                                return;
                                              }
                                              if (context.mounted) Navigator.of(context).pop();
                                            }
                                          },
                                        ),
                                    ],
                                  ],
                                );
                              },
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
        ));
  }

  Widget _actionButton({
    required BuildContext context,
    required String label,
    required bool outlined,
    required Future<void> Function() onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: SizedBox(
        width: double.infinity,
        child: outlined
            ? OutlinedButton(onPressed: onPressed, child: Text(label))
            : ElevatedButton(onPressed: onPressed, child: Text(label)),
      ),
    );
  }

  Widget _buildTrailingWidget(TransactionDetailsListItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
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
  }

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
