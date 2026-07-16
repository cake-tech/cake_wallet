import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item.dart';
import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/copy_wrapper.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/src/screens/transaction_details/blockexplorer_list_item.dart';
import 'package:cake_wallet/src/screens/transaction_details/transaction_details_list_item.dart';
import 'package:cake_wallet/src/screens/trade_details/trade_details_list_card.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/src/widgets/new_list_row/new_list_section.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/utils/show_bar.dart';
import 'package:cake_wallet/view_model/payjoin_details_view_model.dart';
import 'package:cw_core/amount/money.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class PayjoinDetailsModal extends StatefulWidget {
  const PayjoinDetailsModal({super.key, required this.payjoinDetailsViewModel});

  final PayjoinDetailsViewModel payjoinDetailsViewModel;

  @override
  State<PayjoinDetailsModal> createState() => _PayjoinDetailsModalState();
}

class _PayjoinDetailsModalState extends State<PayjoinDetailsModal> {
  @override
  void dispose() {
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
    final amountDisplay = getIt.get<AppStore>().amountParsingProxy
        .asDisplayStringWithSymbol(Money(session.amount, CryptoCurrency.btc));

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
                child: Container(
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
                  child: Column(
                    children: [
                      ModalTopBar(
                        title: S.current.payjoin_details,
                        leadingIcon: Icon(Icons.close),
                        onLeadingPressed: Navigator.of(context).pop,
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          controller: controller,
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
                                        .whereType<TransactionDetailsListItem>()
                                        .where((i) => i is! TradeDetailsListCardItem)
                                        .toList();
                                    return Column(
                                      spacing: 12,
                                      children: [
                                        NewListSections(sections: {
                                          "": items.map((item) {
                                                final shouldBuildBottomWidget =
                                                    item.value.length > 25;
                                                return ListItemRegularRow(
                                                    copyableText: item.value,
                                                    showArrow: item is BlockExplorerListItem,
                                                    keyValue:
                                                        ((item.key as ValueKey?)?.value as String?) ??
                                                            item.title,
                                                    label: item.title,
                                                    onTap: item is BlockExplorerListItem
                                                        ? item.onTap
                                                        : null,
                                                    trailingWidget: shouldBuildBottomWidget
                                                        ? null
                                                        : _buildTrailingWidget(item),
                                                    bottomWidget: shouldBuildBottomWidget
                                                        ? _buildBottomWidget(item)
                                                        : null);
                                              }).whereType<ListItem>().toList(),
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
      child: Text(
        item.value,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }

  Widget _buildBottomWidget(TransactionDetailsListItem item) {
    return Text(
      item.value,
      style: TextStyle(
          fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
    );
  }
}
