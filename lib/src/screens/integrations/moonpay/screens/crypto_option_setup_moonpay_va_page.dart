import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/integrations/moonpay/widgets/moonpay_dual_currency_icon_widget.dart';
import 'package:cake_wallet/src/screens/integrations/moonpay/widgets/moonpay_option_row_widget.dart';
import 'package:cake_wallet/view_model/integrations/moonpay_virtual_account/moonpay_virtual_account_view_model.dart';
import 'package:flutter/material.dart';

import 'network_option_setup_moonpay_va_page.dart';

class MoonPayVACryptoOptionPage extends BasePage {
  MoonPayVACryptoOptionPage(this.viewModel);

  final MoonPayVirtualAccountViewModel viewModel;

  @override
  String get title => 'Wallet Currency';

  @override
  Widget body(BuildContext context) {
    final textTextStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w400,
        fontSize: 12);
    final stablecoins = viewModel.allAvailableStablecoins;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Column(
        children: [
          const SizedBox(height: 24),
          DualCurrencyIcon(
              leftImagePath: 'assets/images/eurc_icon.svg',
              rightImagePath: 'assets/images/usdc_icon.svg',
              backgroundColor: Theme.of(context).colorScheme.surface),
          const SizedBox(height: 24),
          Text(
            'Select the crypto that you will receive on your wallet',
            textAlign: TextAlign.center,
            style: textTextStyle,
          ),
          const SizedBox(height: 12),
          Text(
            'Fiat deposits into your account will automatically convert into your chosen stablecoin or token',
            textAlign: TextAlign.center,
            style: textTextStyle,
          ),
          const SizedBox(height: 24),
          OptionCard(
            children: stablecoins.asMap().entries.map((entry) {
              final stablecoin = entry.value;
              return Column(
                children: [
                  OptionRow(
                    title: stablecoin.title,
                    image: stablecoin.iconPath,
                    subtitle: '',
                    showChevron: true,
                    onTap: () {
                      viewModel.selectStablecoinKey(stablecoin);
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => MoonPayVANetworkOptionPage(viewModel),
                        ),
                      );
                    },
                  ),
                ],
              );
            }).toList(),
          )
        ],
      ),
    );
  }
}
