import 'package:cake_wallet/new-ui/widgets/asset_tile.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_view_model.dart';
import 'package:cw_core/currency_for_wallet_type.dart';
import 'package:flutter/material.dart';

class NewWalletListPage extends StatelessWidget {
  const NewWalletListPage({super.key, required this.walletListViewModel});

  final WalletListViewModel walletListViewModel;


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView.builder(
        itemCount: walletListViewModel.wallets.length,
        itemBuilder: (context, index){
          final wallet = walletListViewModel.wallets[index];

          return AssetTile(iconPath: walletTypeToCryptoCurrency(wallet.type).iconPath!, name: wallet.name, amount: "123 BTC", amountFiat: "123 USD");
        },
      )
    );
  }
}
