import 'package:cake_wallet/new-ui/widgets/coins_page/cards/balance_card.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cake_wallet/view_model/monero_account_list/monero_account_list_view_model.dart';
import 'package:flutter/material.dart';

class CardCustomizer extends StatelessWidget {
  const CardCustomizer({super.key, required this.dashboardViewModel, this.accountListViewModel});

  final DashboardViewModel dashboardViewModel;
  final MoneroAccountListViewModel? accountListViewModel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ModalTopBar(
          title: accountListViewModel == null ? "Edit Card" : "Edit Account",
          leadingIcon: Icon(Icons.close),
          trailingIcon: Icon(Icons.delete_forever),
          onLeadingPressed: () => Navigator.of(context).pop(),
          onTrailingPressed: () {},
        ),
        //TODO change acc name
        if (accountListViewModel != null) Container(),
        BalanceCard(
            width: MediaQuery.of(context).size.width * 0.9,
            selected: false,
            accountName: '',
            accountBalance: '',
            balance: '',
            fiatBalance: '',
            assetName: '',
            design: dashboardViewModel.wallet.currency.cardDesign),
      ],
    );
  }
}
