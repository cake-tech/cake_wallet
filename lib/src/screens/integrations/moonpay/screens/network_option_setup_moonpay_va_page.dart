import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/integrations/moonpay/screens/wallet_option_setup_moonpay_va_page.dart';
import 'package:cake_wallet/src/screens/integrations/moonpay/widgets/moonpay_option_row_widget.dart';
import 'package:cake_wallet/view_model/integrations/moonpay_virtual_account/moonpay_virtual_account_view_model.dart';
import 'package:cw_core/currency_for_wallet_type.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';

class MoonPayVANetworkOptionPage extends BasePage {
  MoonPayVANetworkOptionPage(this.viewModel);

  final MoonPayVirtualAccountViewModel viewModel;

  @override
  String get title => 'Destination Network';

  @override
  Widget body(BuildContext context) {
    final textTextStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w400,
        fontSize: 12);
    final networkOptions = viewModel.availableWalletTypesByStablecoinKey;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Text(
            'Select the network that will be used to receive stablecoin funds. This can be changed later.',
            textAlign: TextAlign.center,
            style: textTextStyle,
          ),
          const SizedBox(height: 24),
          OptionCard(
            children: networkOptions.asMap().entries.map((entry) {
              final networkOption = entry.value;
              return Column(
                children: [
                  OptionRow(
                    title: walletTypeToString(networkOption),
                    image: getCryptoCurrencyIconForWalletListItem(networkOption),
                    subtitle: '',
                    showChevron: true,
                    onTap: () {
                      viewModel.selectNetwork(networkOption);
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => MoonPayVAWalletOptionPage(viewModel),
                        ),
                      );
                    },
                  ),
                ],
              );
            }).toList(growable: false),
          )
        ],
      ),
    );
  }
}
