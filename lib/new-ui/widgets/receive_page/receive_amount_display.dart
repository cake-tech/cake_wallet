import "package:cake_wallet/new-ui/widgets/money/money_text.dart";
import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_list_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class ReceiveAmountDisplay extends StatelessWidget {
  const ReceiveAmountDisplay(
      {super.key, required this.walletAddressListViewModel, required this.largeQrMode});

  final WalletAddressListViewModel walletAddressListViewModel;
  final bool largeQrMode;

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) => AnimatedOpacity(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        opacity: largeQrMode || walletAddressListViewModel.displayAmount == null ? 0 : 1,
        child: AnimatedAlign(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          heightFactor: largeQrMode || walletAddressListViewModel.displayAmount == null ? 0 : 1,
          alignment: Alignment.topCenter,
          // Amount, currency symbol and fiat equivalent describe one value, so
          // they are announced as a single node.
          child: MergeSemantics(
            child: Container(
              width: double.infinity,
              child: Row(
                spacing: 4,
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (walletAddressListViewModel.displayAmount != null)
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Theme.of(context).colorScheme.surfaceContainer,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: MoneyText(
                        walletAddressListViewModel.displayAmount!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                if (!walletAddressListViewModel.isFiatDisabled && walletAddressListViewModel.fiatAmount != null)
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: MoneyText(
                      walletAddressListViewModel.fiatAmount!,
                        trimZeros: false,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
              ],),
            ),
          ),
        ),
      ),
    );
  }
}
