import 'package:cake_wallet/store/dashboard/fiat_conversion_store.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_list_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';


class ReceiveAmountDisplay extends StatelessWidget {
  const ReceiveAmountDisplay({super.key, required this.walletAddressListViewModel, required this.largeQrMode});

  final WalletAddressListViewModel walletAddressListViewModel;
  final bool largeQrMode;


  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_)=>AnimatedOpacity(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        opacity: largeQrMode || walletAddressListViewModel.amount.isEmpty ? 0 : 1,
        child: AnimatedAlign(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          heightFactor: largeQrMode || walletAddressListViewModel.amount.isEmpty ? 0 : 1,
          alignment: Alignment.topCenter,
          child: Container(
            width: double.infinity,
            child: Row(
              spacing: 4,
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Theme.of(context).colorScheme.surfaceContainer
                  ),
                  child:
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      spacing: 8.0,
                      children: [
                        Text(walletAddressListViewModel.amount, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize:16,fontWeight: FontWeight.w500),),
                        Text(walletAddressListViewModel.wallet.currency.name.toUpperCase(), style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize:16,fontWeight: FontWeight.w500))
                      ],
                    ),
                  ),

                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text("${walletAddressListViewModel.fiatAmount} ${walletAddressListViewModel.fiatCurrency.name}", style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 16,fontWeight: FontWeight.w500),),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
