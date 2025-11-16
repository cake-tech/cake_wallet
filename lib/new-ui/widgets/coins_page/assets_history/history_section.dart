import 'package:cake_wallet/new-ui/widgets/coins_page/assets_history/history_tile.dart';
import 'package:cake_wallet/utils/date_formatter.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cake_wallet/view_model/dashboard/date_section_item.dart';
import 'package:cake_wallet/view_model/dashboard/transaction_list_item.dart';
import 'package:flutter/material.dart';


class HistorySection extends StatelessWidget {
  const HistorySection({super.key, required this.dashboardViewModel});

  final DashboardViewModel dashboardViewModel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: dashboardViewModel.items.length,
        itemBuilder: (context, index) {
          final prevItem = index == 0 ? null : dashboardViewModel.items[index - 1];
          final item = dashboardViewModel.items[index];
          final nextItem = index == dashboardViewModel.items.length - 1 ? null : dashboardViewModel.items[index + 1];


          if(item is TransactionListItem) {
            final transaction = item.transaction;
            final transactionType =
            dashboardViewModel.getTransactionType(transaction);

            return HistoryTile(
              title: item.formattedTitle + item.formattedStatus + transactionType,
              date: DateFormatter.convertDateTimeToReadableString(item.date),
              amount: item.formattedCryptoAmount,
              amountFiat: item.formattedFiatAmount,
              roundedBottom: !(nextItem is TransactionListItem),
              roundedTop: !(prevItem is TransactionListItem),
              bottomSeparator: nextItem is TransactionListItem,
              direction: item.transaction.direction,
              pending: item.transaction.isPending
            );


          } else if(item is DateSectionItem){
            return Text(DateFormatter.convertDateTimeToReadableString(item.date));
          }

          else return Text(item.runtimeType.toString());
        },
      ),
    );
  }
}
