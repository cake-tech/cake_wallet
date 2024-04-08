import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/ionia/widgets/ionia_tile.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/typography.dart';
import 'package:cake_wallet/view_model/ionia/cake_pay_account_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/themes/extensions/send_page_theme.dart';

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
                overlayColor: MaterialStateColor.resolveWith(
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
      style: textMediumSemiBold(
        color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
      ),
    );
  }

  @override
  Widget body(BuildContext context) {
    return ScrollableWithBottomSection(
      contentPadding: EdgeInsets.all(24),
      content: Column(
        children: [
          _GradiantContainer(
            content: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Observer(
                    builder: (_) => RichText(
                          text: TextSpan(
                            text: '${cakePayAccountViewModel.countOfMerch}',
                            style: textLargeSemiBold(),
                            children: [
                              TextSpan(
                                  text: ' ${S.of(context).active_cards}',
                                  style: textSmall(color: Colors.white.withOpacity(0.7))),
                            ],
                          ),
                        )),
                InkWell(
                  onTap: () {
                    Navigator.pushNamed(context, Routes.ioniaAccountCardsPage)
                    .then((_) => cakePayAccountViewModel.updateUserGiftCards());
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      S.of(context).view_all,
                      style: textSmallSemiBold(),
                    ),
                  ),
                )
              ],
            ),
          ),
          SizedBox(height: 20),
          Observer(
            builder: (_) => IoniaTile(title: S.of(context).email_address, subTitle: cakePayAccountViewModel.email),
          ),
          Divider()
        ],
      ),
      bottomSectionPadding: EdgeInsets.all(30),
      bottomSection: Column(
        children: [
          PrimaryButton(
            color: Theme.of(context).primaryColor,
            textColor: Colors.white,
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

class _GradiantContainer extends StatelessWidget {
  const _GradiantContainer({
    Key? key,
    required this.content,
  }) : super(key: key);

  final Widget content;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: content,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).extension<SendPageTheme>()!.secondGradientColor,
            Theme.of(context).extension<SendPageTheme>()!.firstGradientColor,
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
    );
  }
}
