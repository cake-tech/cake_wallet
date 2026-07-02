import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/trade_details/trade_details_list_card.dart';
import 'package:cake_wallet/src/screens/trade_details/trade_details_status_item.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/src/widgets/list_row.dart';
import 'package:cake_wallet/src/widgets/standard_list.dart';
import 'package:cake_wallet/src/widgets/standard_list_card.dart';
import 'package:cake_wallet/src/widgets/standard_list_status_row.dart';
import 'package:cake_wallet/themes/core/material_base_theme.dart';
import 'package:cake_wallet/utils/show_bar.dart';
import 'package:cake_wallet/view_model/payjoin_details_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class PayjoinDetailsPage extends BasePage {
  PayjoinDetailsPage({required this.payjoinDetailsViewModel});

  @override
  String get title => S.current.payjoin_details;

  final PayjoinDetailsViewModel payjoinDetailsViewModel;

  @override
  Widget body(BuildContext context) =>
      PayjoinDetailsPageBody(payjoinDetailsViewModel, currentTheme);
}

class PayjoinDetailsPageBody extends StatefulWidget {
  PayjoinDetailsPageBody(this.payjoinDetailsViewModel, this.currentTheme);

  final PayjoinDetailsViewModel payjoinDetailsViewModel;
  final MaterialThemeBase currentTheme;

  @override
  State<PayjoinDetailsPageBody> createState() => _PayjoinDetailsPageBodyState();
}

class _PayjoinDetailsPageBodyState extends State<PayjoinDetailsPageBody> {
  @override
  void dispose() {
    super.dispose();
    widget.payjoinDetailsViewModel.listener.cancel();
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
    return Observer(
      builder: (_) {
        final items = vm.items;
        var buttonCount = 0;
        if (vm.canCancel) buttonCount++;
        if (vm.canFallback) buttonCount++;

        return SectionStandardList(
            sectionCount: 1,
            itemCounter: (_) => items.length + buttonCount,
            itemBuilder: (__, index) {
              if (index < items.length) {
                final item = items[index];

                if (item is DetailsListStatusItem) {
                  return StandardListStatusRow(
                    title: item.title,
                    value: item.value,
                    status: item.status,
                  );
                }

                if (item is TradeDetailsListCardItem) {
                  return TradeDetailsStandardListCard(
                    id: item.id,
                    create: item.createdAt,
                    pair: item.pair,
                    currentTheme: widget.currentTheme.type,
                    onTap: item.onTap,
                  );
                }

                return GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: item.value));
                    showBar<void>(context, S.of(context).transaction_details_copied(item.title));
                  },
                  child: ListRow(title: '${item.title}:', value: item.value),
                );
              }

              final buttonIdx = index - items.length;
              var buttonWidgets = <Widget>[];
              if (vm.canCancel) buttonWidgets.add(_cancelButton(context, vm));
              if (vm.canFallback) buttonWidgets.add(_fallbackButton(context, vm));
              return buttonWidgets[buttonIdx];
            });
      },
    );
  }

  Widget _cancelButton(BuildContext context, PayjoinDetailsViewModel vm) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () async {
            final confirmed = await _confirmCancel(context);
            if (confirmed == true) {
              vm.cancel();
              Navigator.of(context).pop();
            }
          },
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Widget _fallbackButton(BuildContext context, PayjoinDetailsViewModel vm) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () async {
            final confirmed = await _confirmFallback(context);
            if (confirmed == true) {
              try {
                await vm.fallbackBroadcast();
              } catch (e) {
                showBar<void>(context, 'Fallback failed: $e');
                return;
              }
              Navigator.of(context).pop();
            }
          },
          child: const Text('Fallback Broadcast'),
        ),
      ),
    );
  }
}
