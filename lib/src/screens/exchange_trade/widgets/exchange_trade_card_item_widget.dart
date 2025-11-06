import 'package:cake_wallet/entities/priority_for_wallet_type.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/src/widgets/list_row.dart';
import 'package:cake_wallet/src/widgets/picker.dart';
import 'package:cake_wallet/utils/show_bar.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/exchange/exchange_trade_view_model.dart';
import 'package:cake_wallet/view_model/send/fees_view_model.dart';
import 'package:cake_wallet/view_model/send/output.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class ExchangeTradeCardItemWidget extends StatelessWidget {
  ExchangeTradeCardItemWidget({
    required this.isReceiveDetailsCard,
    required this.exchangeTradeViewModel,
    Key? key,
  })  : feesViewModel = exchangeTradeViewModel.feesViewModel,
        output = exchangeTradeViewModel.output;

  final Output output;
  final bool isReceiveDetailsCard;
  final FeesViewModel feesViewModel;
  final ExchangeTradeViewModel exchangeTradeViewModel;

  @override
  Widget build(BuildContext context) {
    final copyImage = Image.asset(
      'assets/images/copy_content.png',
      height: 16,
      width: 16,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );

    return Container(
      width: double.infinity,
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(height: 10),
          ...exchangeTradeViewModel.items
              .where((item) => item.isReceiveDetail == isReceiveDetailsCard)
              .map(
                (item) => TradeItemRowWidget(
                  title: item.title,
                  value: item.data,
                  isCopied: item.isCopied,
                  copyImage: copyImage,
                ),
              )
              .toList(),
          if (!isReceiveDetailsCard && exchangeTradeViewModel.isSendable) ...[
            if (feesViewModel.hasFees)
              FeeSelectionWidget(
                feesViewModel: feesViewModel,
                output: output,
                onTap: () => pickTransactionPriority(context, output),
              ),
            if (exchangeTradeViewModel.sendViewModel.hasCoinControl)
              CoinControlWidget(
                onTap: () => Navigator.of(context).pushNamed(
                  Routes.unspentCoinsList,
                  arguments: exchangeTradeViewModel.sendViewModel.coinTypeToSpendFrom,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Future<void> pickTransactionPriority(BuildContext context, Output output) async {
    final items = priorityForWalletType(feesViewModel.walletType);
    final selectedItem = items.indexOf(feesViewModel.transactionPriority);
    final customItemIndex = feesViewModel.getCustomPriorityIndex(items);
    final isBitcoinWallet = feesViewModel.walletType == WalletType.bitcoin;
    final maxCustomFeeRate = feesViewModel.maxCustomFeeRate?.toDouble();
    double? customFeeRate = isBitcoinWallet ? feesViewModel.customBitcoinFeeRate.toDouble() : null;

    await showPopUp<void>(
      context: context,
      builder: (BuildContext context) {
        int selectedIdx = selectedItem;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Picker(
              items: items,
              displayItem: (TransactionPriority priority) =>
                  feesViewModel.displayFeeRate(priority, customFeeRate?.round()),
              selectedAtIndex: selectedIdx,
              customItemIndex: customItemIndex,
              maxValue: maxCustomFeeRate,
              title: S.of(context).please_select,
              headerEnabled: !isBitcoinWallet,
              closeOnItemSelected: !isBitcoinWallet,
              mainAxisAlignment: MainAxisAlignment.center,
              sliderValue: customFeeRate,
              onSliderChanged: (double newValue) => setState(() => customFeeRate = newValue),
              onItemSelected: (TransactionPriority priority) async {
                feesViewModel.setTransactionPriority(priority);
                setState(() => selectedIdx = items.indexOf(priority));
                await output.calculateEstimatedFee();
                if (feesViewModel.isLowFee) {
                  _showFeeAlert(context);
                }
              },
            );
          },
        );
      },
    );
    if (isBitcoinWallet) {
      feesViewModel.customBitcoinFeeRate = customFeeRate!.round();
      if (feesViewModel.showAlertForCustomFeeRate()) {
        _showFeeAlert(context);
      }
    }
  }

  void _showFeeAlert(BuildContext context) async {
    final confirmed = await showPopUp<bool>(
            context: context,
            builder: (dialogContext) {
              return AlertWithTwoActions(
                  alertTitle: S.of(context).low_fee,
                  alertContent: S.of(context).low_fee_alert,
                  leftButtonText: S.of(context).ignor,
                  rightButtonText: S.of(context).use_suggested,
                  actionLeftButton: () => Navigator.of(dialogContext).pop(false),
                  actionRightButton: () => Navigator.of(dialogContext).pop(true));
            }) ??
        false;
    if (confirmed) {
      feesViewModel.setDefaultTransactionPriority();
    }
  }
}

class TradeItemRowWidget extends StatelessWidget {
  final String title;
  final String value;
  final bool isCopied;
  final Image copyImage;

  const TradeItemRowWidget({
    required this.title,
    required this.value,
    required this.isCopied,
    required this.copyImage,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: GestureDetector(
        onTap: () {
          if (!isCopied) return;
          Clipboard.setData(ClipboardData(text: value));
          showBar<void>(context, S.of(context).transaction_details_copied(title));
        },
        child: ListRow(
          padding: EdgeInsets.zero,
          title: title,
          value: value,
          image: isCopied ? copyImage : null,
          color: Colors.transparent,
          hintTextColor: Theme.of(context).colorScheme.onSurfaceVariant,
          mainTextColor: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

class FeeSelectionWidget extends StatelessWidget {
  final FeesViewModel feesViewModel;
  final Output output;
  final VoidCallback onTap;

  const FeeSelectionWidget({
    required this.feesViewModel,
    required this.output,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) => GestureDetector(
        key: ValueKey('exchange_trade_card_item_widget_select_fee_priority_button_key'),
        onTap: feesViewModel.hasFeesPriority ? onTap : () {},
        child: Container(
          padding: EdgeInsets.only(top: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                S.of(context).send_estimated_fee,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${output.estimatedFee} ${feesViewModel.currency}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      if (!feesViewModel.isFiatDisabled)
                        Padding(
                          padding: EdgeInsets.only(top: 5),
                          child: Text(
                            '${output.estimatedFeeFiatAmount} ${feesViewModel.fiat.title}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 2, left: 5),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CoinControlWidget extends StatelessWidget {
  final VoidCallback onTap;

  const CoinControlWidget({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: ValueKey('exchange_trade_card_item_widget_unspent_coin_button_key'),
      onTap: onTap,
      child: Container(
        color: Colors.transparent,
        padding: EdgeInsets.only(top: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              S.of(context).coin_control,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
