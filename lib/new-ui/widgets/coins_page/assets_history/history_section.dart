import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/assets_history/anonpay_history_tile.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/assets_history/history_order_tile.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/assets_history/history_tile.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/assets_history/history_trade_tile.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/assets_history/payjoin_history_tile.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/utils/date_formatter.dart';
import 'package:cake_wallet/view_model/dashboard/anonpay_transaction_list_item.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cake_wallet/view_model/dashboard/date_section_item.dart';
import 'package:cake_wallet/view_model/dashboard/order_list_item.dart';
import 'package:cake_wallet/view_model/dashboard/payjoin_transaction_list_item.dart';
import 'package:cake_wallet/view_model/dashboard/trade_list_item.dart';
import 'package:cake_wallet/view_model/dashboard/transaction_list_item.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:intl/intl.dart';

class HistorySection extends StatelessWidget {
  const HistorySection({super.key, required this.dashboardViewModel});

  final DashboardViewModel dashboardViewModel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Observer(
        builder: (_) => (dashboardViewModel.items.isEmpty &&
                dashboardViewModel.status is! SyncingSyncStatus)
            ? Padding(
                padding: EdgeInsets.only(top: 24),
                child: Text(S.of(context).transactions_will_appear_here,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Theme.of(context).colorScheme.onSurfaceVariant)))
            : ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          itemCount: dashboardViewModel.items.length,
          itemBuilder: (context, index) => Observer(builder: (_) {
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

              if (item.hasTokens && item.assetOfTransaction == null) {
                return Container();
              }

                    CryptoCurrency? asset;
                    if (transaction.additionalInfo["isLightning"] == true)
                      asset = CryptoCurrency.btcln;

                    return GestureDetector(
                      onTap: () => Navigator.of(context)
                          .pushNamed(Routes.transactionDetails, arguments: transaction),
                      child: HistoryTile(
                        title: item.formattedTitle + transactionType,
                        date: DateFormat('HH:mm').format(transaction.date),
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

              return GestureDetector(
                onTap: () => Navigator.of(context)
                    .pushNamed(Routes.tradeDetails, arguments: trade),
                child: HistoryTradeTile(
                  from: tradeFrom!,
                  to: tradeTo!,
                  date: DateFormat('HH:mm').format(item.trade.createdAt!),
                  amount: trade.amountFormatted(),
                  receiveAmount: trade.receiveAmountFormatted(),
                  roundedBottom: roundedBottom,
                  roundedTop: roundedTop,
                  bottomSeparator: !roundedBottom,
                  swapState: trade.state,
                ),
              );
            } else if (item is DateSectionItem) {
              return Padding(
                  padding: EdgeInsets.only(left: 8.0, bottom: 8.0, top: 18.0),
                  child: Text(DateFormatter.convertDateTimeToReadableString(item.date),
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)));
            }else if(item is OrderListItem){
              return GestureDetector(
                onTap: () => Navigator.of(context)
                    .pushNamed(Routes.orderDetails, arguments: item.order),
                child: HistoryOrderTile(
                  date: DateFormat('HH:mm').format(item.order.createdAt),
                  amount: item.orderFormattedAmount,
                  amountFiat: "USD 0.00",
                  roundedBottom: roundedBottom,
                  roundedTop: roundedTop,
                  bottomSeparator: !roundedBottom,
                ),
              );
            } else if (item is PayjoinTransactionListItem) {
              final session = item.session;

              return GestureDetector(
                onTap: () => Navigator.of(context).pushNamed(
                  Routes.payjoinDetails,
                  arguments: [item.sessionId, item.transaction],
                ),
                child: PayjoinHistoryTile(
                    createdAt: DateFormat('HH:mm').format(session.inProgressSince!),
                    amount: dashboardViewModel.appStore.amountParsingProxy
                        .getDisplayCryptoString(session.amount.toInt(), CryptoCurrency.btc),
                    currency: item.transaction?.from ?? "BTC",
                    state: item.status,
                    isSending: session.isSenderSession,
                    roundedTop: roundedTop,
                    roundedBottom: roundedBottom,
                    bottomSeparator: !roundedBottom),
              );
            } else if (item is AnonpayTransactionListItem) {
              final transactionInfo = item.transaction;

              return GestureDetector(
                  onTap: () => Navigator.of(context)
                      .pushNamed(Routes.anonPayDetailsPage, arguments: transactionInfo),
                  child: AnonpayHistoryTile(
                      provider: transactionInfo.provider,
                      createdAt: DateFormat('HH:mm').format(transactionInfo.createdAt),
                      amount: transactionInfo.fiatAmount?.toString() ??
                          (transactionInfo.amountTo?.toString() ?? ''),
                      currency: transactionInfo.fiatAmount != null
                          ? transactionInfo.fiatEquiv ?? ''
                          : CryptoCurrency.fromFullName(transactionInfo.coinTo).name.toUpperCase(),
                      roundedTop: roundedTop,
                      roundedBottom: roundedBottom,
                      bottomSeparator: !roundedBottom));
            } else
              return Text(item.runtimeType.toString());
          }),
        ),
      ),
    );
  }
}
