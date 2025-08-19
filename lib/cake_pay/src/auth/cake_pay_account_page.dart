import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/cake_pay/src/widgets/cake_pay_tile.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/view_model/cake_pay/cake_pay_account_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class CakePayAccountPage extends BasePage {
  CakePayAccountPage(this.cakePayAccountViewModel);

  final CakePayAccountViewModel cakePayAccountViewModel;

  @override
  Widget leading(BuildContext context) {
    return MergeSemantics(
      child: SizedBox(
        height: 37,
        width: 37,
        child: ButtonTheme(
          minWidth: double.minPositive,
          child: Semantics(
            label: S.of(context).seed_alert_back,
            child: TextButton(
              style: ButtonStyle(
                overlayColor: WidgetStateColor.resolveWith(
                        (states) => Colors.transparent),
              ),
              onPressed: () => Navigator.pop(context),
              child: backButton(context),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget middle(BuildContext context) {
    return Text(
      S.current.account,
      style:  Theme.of(context).textTheme.titleMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  @override
  Widget body(BuildContext context) {
    return ScrollableWithBottomSection(
      contentPadding: EdgeInsets.all(24),
      content: Column(
        children: [
          SizedBox(height: 20),
          Observer(
            builder: (_) => Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    width: 1.0,
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              ),
              child: CakePayTile(
                title: S.of(context).email_address, 
                subTitle: cakePayAccountViewModel.email
              ),
            ),
          ),
        ],
      ),
      bottomSectionPadding: EdgeInsets.all(30),
      bottomSection: Column(
        children: [
          PrimaryButton(
            color: Theme.of(context).colorScheme.primary,
            textColor: Theme.of(context).colorScheme.onPrimary,
            text: S.of(context).logout,
            onPressed: () {
              cakePayAccountViewModel.logout();
              Navigator.pushNamedAndRemoveUntil(context, Routes.dashboard, (route) => false);
            },
          ),
        ],
      ),
    );
  }
}
