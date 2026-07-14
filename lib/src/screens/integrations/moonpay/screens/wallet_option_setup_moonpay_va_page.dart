import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/integrations/moonpay/widgets/moonpay_option_row_widget.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/view_model/integrations/moonpay_virtual_account/moonpay_virtual_account_view_model.dart';
import 'package:cw_core/currency_for_wallet_type.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';

class MoonPayVAWalletOptionPage extends BasePage {
  MoonPayVAWalletOptionPage(this.viewModel);

  final MoonPayVirtualAccountViewModel viewModel;

  @override
  String get title => 'Destination Wallet';

  @override
  Widget body(BuildContext context) {
    final textTextStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w400,
        fontSize: 12);

    final type = viewModel.selectedWalletType;
    final selectedNetworkOptionIcon =
        type == null ? '' : getCryptoCurrencyIconForWalletListItem(type);

    final walletTypeString = type == null ? '' : walletTypeToString(type);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Column(
        children: [
          const SizedBox(height: 24),
          CakeImageWidget(imageUrl: selectedNetworkOptionIcon, height: 60, width: 60),
          const SizedBox(height: 40),
          Text(
            'Select a $walletTypeString wallet or address to receive stablecoin funds. This can be changed later',
            textAlign: TextAlign.center,
            style: textTextStyle,
          ),
          const SizedBox(height: 24),
          OptionCard(
              children: viewModel.availableWalletsForSelectedStablecoin
                  .map((wallet) => Column(
                        children: [
                          OptionRow(
                            title: wallet.name,
                            image: getCryptoCurrencyIconForWalletListItem(wallet.type),
                            subtitle: '',
                            showChevron: true,
                            onTap: () {
                              viewModel.selectWallet(wallet);
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ))
                  .toList(growable: false))
        ],
      ),
    );
  }
}
