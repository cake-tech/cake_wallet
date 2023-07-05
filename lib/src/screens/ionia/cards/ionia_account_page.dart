import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/ionia/widgets/ionia_tile.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/typography.dart';
import 'package:cake_wallet/view_model/ionia/ionia_account_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/themes/extensions/send_page_theme.dart';

class IoniaAccountPage extends BasePage {
  IoniaAccountPage(this.ioniaAccountViewModel);

  final IoniaAccountViewModel ioniaAccountViewModel;

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
                            text: '${ioniaAccountViewModel.countOfMerch}',
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
                    .then((_) => ioniaAccountViewModel.updateUserGiftCards());
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
          SizedBox(height: 8),
          //Row(
          //  mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //  children: [
          //    _GradiantContainer(
          //      padding: EdgeInsets.all(16),
          //      width: deviceWidth * 0.28,
          //      content: Column(
          //        crossAxisAlignment: CrossAxisAlignment.start,
          //        children: [
          //          Text(
          //            S.of(context).total_saving,
          //            style: textSmall(),
          //          ),
          //          SizedBox(height: 8),
          //          Text(
          //            '\$100',
          //            style: textMediumSemiBold(),
          //          ),
          //        ],
          //      ),
          //    ),
          //    _GradiantContainer(
          //      padding: EdgeInsets.all(16),
          //      width: deviceWidth * 0.28,
          //      content: Column(
          //        crossAxisAlignment: CrossAxisAlignment.start,
          //        children: [
          //          Text(
          //            S.of(context).last_30_days,
          //            style: textSmall(),
          //          ),
          //          SizedBox(height: 8),
          //          Text(
          //            '\$100',
          //            style: textMediumSemiBold(),
          //          ),
          //        ],
          //      ),
          //    ),
          //    _GradiantContainer(
          //      padding: EdgeInsets.all(16),
          //      width: deviceWidth * 0.28,
          //      content: Column(
          //        crossAxisAlignment: CrossAxisAlignment.start,
          //        children: [
          //          Text(
          //            S.of(context).avg_savings,
          //            style: textSmall(),
          //          ),
          //          SizedBox(height: 8),
          //          Text(
          //            '10%',
          //            style: textMediumSemiBold(),
          //          ),
          //        ],
          //      ),
          //    ),
          //  ],
          //),
          SizedBox(height: 40),
          Observer(
            builder: (_) => IoniaTile(title: S.of(context).email_address, subTitle: ioniaAccountViewModel.email ?? ''),
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
              ioniaAccountViewModel.logout();
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
