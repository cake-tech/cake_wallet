import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/dashboard/pages/balance/balance_row_widget.dart';
import 'package:cake_wallet/src/screens/integrations/deuro/widgets/interest_card_widget.dart';
import 'package:cake_wallet/src/screens/integrations/deuro/widgets/savings_card_widget.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cake_wallet/view_model/integrations/deuro_view_model.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class DEuroSavingsPage extends BasePage {
  final DEuroViewModel _dEuroViewModel;

  DEuroSavingsPage(this._dEuroViewModel);

  @override
  String get title => S.current.deuro_savings;

  @override
  Widget body(BuildContext context) => Container(
        padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
        width: double.infinity,
        child: Column(
          children: <Widget>[
            Observer(
              builder: (_) => SavingsCard(
                isDarkTheme: currentTheme.isDark,
                interestRate: "${_dEuroViewModel.interestRate}%",
                savingsBalance: _dEuroViewModel.savingsBalance,
                currency: CryptoCurrency.deuro,
              ),
            ),
            Observer(
              builder: (_) => InterestCardWidget(
                isDarkTheme: currentTheme.isDark,
                title: 'Collected Interest',
                collectedInterest: _dEuroViewModel.accruedInterest,
              ),
            ),
          ],
        ),
      );
}
