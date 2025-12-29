import 'package:cake_wallet/new-ui/widgets/coins_page/assets_history/history_order_tile.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/assets_history/history_tile.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/assets_history/history_trade_tile.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/utils/date_formatter.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cake_wallet/view_model/dashboard/date_section_item.dart';
import 'package:cake_wallet/view_model/dashboard/order_list_item.dart';
import 'package:cake_wallet/view_model/dashboard/trade_list_item.dart';
import 'package:cake_wallet/view_model/dashboard/transaction_list_item.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class HistorySection extends StatelessWidget {
  const HistorySection({super.key, required this.dashboardViewModel});

  final DashboardViewModel dashboardViewModel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Observer(
        builder: (_) => ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: dashboardViewModel.items.length,
          itemBuilder: (context, index) {
            final prevItem = index == 0 ? null : dashboardViewModel.items[index - 1];
            final item = dashboardViewModel.items[index];
            final nextItem = index == dashboardViewModel.items.length - 1
                ? null
                : dashboardViewModel.items[index + 1];

            final roundedBottom = (nextItem == null || nextItem is DateSectionItem);
            final roundedTop = (prevItem == null || prevItem is DateSectionItem);


            if (item is TransactionListItem) {
              final transaction = item.transaction;
              final transactionType = dashboardViewModel.getTransactionType(transaction);

              CryptoCurrency? asset;
              if (transaction.additionalInfo["isLightning"] == true)
                asset = CryptoCurrency.btcln;

              return GestureDetector(
                onTap: () => Navigator.of(context)
                    .pushNamed(Routes.transactionDetails, arguments: transaction),
                child: HistoryTile(
                    title: item.formattedTitle + item.formattedStatus + transactionType,
                    date: DateFormatter.convertDateTimeToReadableString(item.date),
                    amount: item.formattedCryptoAmount,
                    amountFiat: item.formattedFiatAmount,
                    roundedBottom: roundedBottom,
                    roundedTop: roundedTop,
                    bottomSeparator: !roundedBottom,
                    direction: item.transaction.direction,
                    pending: item.transaction.isPending,
                    asset: asset,
                ),
              );
            } else if (item is TradeListItem) {
              final trade = item.trade;

              final tradeFrom = trade.fromRaw >= 0 ? trade.from : trade.userCurrencyFrom;

              final tradeTo = trade.toRaw >= 0 ? trade.to : trade.userCurrencyTo;

              return HistoryTradeTile(
                from: tradeFrom!,
                to: tradeTo!,
                date: DateFormatter.convertDateTimeToReadableString(item.date),
                amount: trade.amountFormatted(),
                receiveAmount: trade.receiveAmountFormatted(),
                roundedBottom: roundedBottom,
                roundedTop: roundedTop,
                bottomSeparator: !roundedBottom,
                swapState: trade.state,
              );
            } else if (item is DateSectionItem) {
              return Padding(
                  padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
                  child: Text(DateFormatter.convertDateTimeToReadableString(item.date)));
            }else if(item is OrderListItem){
              return HistoryOrderTile(
                date: DateFormatter.convertDateTimeToReadableString(item.date),
                amount: item.orderFormattedAmount,
                amountFiat: "USD 0.00",
                roundedBottom: roundedBottom,
                roundedTop: roundedTop,
                bottomSeparator: !roundedBottom,
              );
            } else
              return Text(item.runtimeType.toString());
          },
        ),
      ),
    );
  }
}
