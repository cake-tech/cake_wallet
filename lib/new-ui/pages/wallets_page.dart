import 'package:cake_wallet/new-ui/widgets/asset_tile.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_view_model.dart';
import 'package:cw_core/currency_for_wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class NewWalletListPage extends StatelessWidget {
  const NewWalletListPage({super.key, required this.walletListViewModel});

  final WalletListViewModel walletListViewModel;

  @override
  Widget build(BuildContext context) {
    final fiatCurrency = walletListViewModel.fiatCurrency;

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                walletListViewModel.refreshCachedBalances();
              },
              child: Observer(
                builder: (_) => ListView.builder(
                  itemCount: walletListViewModel.wallets.length,
                  itemBuilder: (context, index) {
                    return Observer(
                      builder: (_) {
                        final wallet = walletListViewModel.wallets[index];
                        final currency = walletTypeToCryptoCurrency(wallet.type);
                        final balance = walletListViewModel.cachedBalanceFor(currency);
                        final fiatBalance = walletListViewModel.fiatCachedBalanceFor(currency);
                        final cacheUpdateStatus = walletListViewModel.cacheUpdateStatuses[index];

                        return AssetTile(
                          iconPath: currency.iconPath!,
                          name: wallet.name,
                          amount: "$balance ${currency.name.toUpperCase()}",
                          amountFiat: "$fiatBalance $fiatCurrency",
                          showLoading: !cacheUpdateStatus,
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
