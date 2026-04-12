import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/integrations/moonpay/widgets/moonpay_option_row_widget.dart';
import 'package:cake_wallet/view_model/integrations/moonpay_virtual_account/moonpay_virtual_account_view_model.dart';
import 'package:flutter/material.dart';

import 'crypto_option_setup_moonpay_va_page.dart';

class MoonPayVAFiatOptionPage extends BasePage {
  MoonPayVAFiatOptionPage(this.viewModel);

  final MoonPayVirtualAccountViewModel viewModel;

  @override
  String get title => 'Account Currency';

  @override
  Widget body(BuildContext context) {
    final textTextStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w400,
        fontSize: 12);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Text(
            'Select the fiat currency of your virtual account',
            textAlign: TextAlign.center,
            style: textTextStyle,
          ),
          const SizedBox(height: 24),
          OptionCard(
            children: MoonPayVirtualAccountViewModelBase.availableFiatOptions.map((fiat) {
              return Column(
                children: [
                  OptionRow(
                      title: '${fiat.name} Account',
                      icon: fiat.fiatSymbol,
                      subtitle: '',
                      showChevron: true,
                      onTap: () {
                        viewModel.selectFiat(fiat);
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => MoonPayVACryptoOptionPage(viewModel),
                          ),
                        );
                      }),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
