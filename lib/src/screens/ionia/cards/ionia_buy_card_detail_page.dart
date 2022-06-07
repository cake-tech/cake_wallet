import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/ionia/widgets/text_icon_button.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/src/widgets/discount_badge.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:cake_wallet/typography.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:cake_wallet/generated/i18n.dart';

class IoniaBuyGiftCardDetailPage extends StatelessWidget {
  ThemeBase get currentTheme => getIt.get<SettingsStore>().currentTheme;

  Color get backgroundLightColor => Colors.white;

  Color get backgroundDarkColor => PaletteDark.backgroundColor;

  void onClose(BuildContext context) => Navigator.of(context).pop();

  Widget leading(BuildContext context) {
    if (ModalRoute.of(context).isFirst) {
      return null;
    }

    final _backButton = Icon(
      Icons.arrow_back_ios,
      color: Theme.of(context).primaryTextTheme.title.color,
      size: 16,
    );
    return Padding(
      padding: const EdgeInsets.only(left: 10.0),
      child: SizedBox(
        height: 37,
        width: 37,
        child: ButtonTheme(
          minWidth: double.minPositive,
          child: FlatButton(
              highlightColor: Colors.transparent,
              splashColor: Colors.transparent,
              padding: EdgeInsets.all(0),
              onPressed: () => onClose(context),
              child: _backButton),
        ),
      ),
    );
  }

  Widget middle(BuildContext context) {
    return Text(
      'AppleBees',
      style: TextStyle(
        fontSize: 22,
        fontFamily: 'Lato',
        fontWeight: FontWeight.w900,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final _backgroundColor = currentTheme.type == ThemeType.dark ? backgroundDarkColor : backgroundLightColor;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: ScrollableWithBottomSection(
        contentPadding: EdgeInsets.zero,
        content: Column(
          children: [
            SizedBox(height: 60),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [leading(context), middle(context), DiscountBadge()],
            ),
            SizedBox(height: 36),
            Container(
              padding: EdgeInsets.symmetric(vertical: 24),
              margin: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryTextTheme.subhead.color,
                    Theme.of(context).primaryTextTheme.subhead.decorationColor,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Gift Card Amount',
                    style: textSmall(),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '\$1000.12',
                    style: textXLargeSemiBold(),
                  ),
                  SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bill Amount',
                              style: textSmall(),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '\$1000.00',
                              style: textLargeSemiBold(),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Tip',
                              style: textSmall(),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '\$1000.00',
                              style: textLargeSemiBold(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  Divider(),
                  SizedBox(height: 16),
                  Text(
                    'You Pay',
                    style: textSmall(),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '22.3435345000 XMR',
                    style: textLargeSemiBold(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tip:',
                    style: TextStyle(
                      color: Theme.of(context).primaryTextTheme.title.color,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 4),
                  TipButtonGroup()
                ],
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: TextIconButton(
                label: S.of(context).how_to_use_card,
                onTap: () {},
              ),
            ),
          ],
        ),
        bottomSection: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: PrimaryButton(
                onPressed: () => purchaseCard(context),
                text: S.of(context).purchase_gift_card,
                color: Theme.of(context).accentTextTheme.body2.color,
                textColor: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(S.of(context).settings_terms_and_conditions,
                style: textMediumSemiBold(
                  color: Theme.of(context).primaryTextTheme.body1.color,
                ).copyWith(fontSize: 12)),
            SizedBox(height: 16)
          ],
        ),
      ),
    );
  }
}

void purchaseCard(BuildContext context) {
  showPopUp<void>(
      context: context,
      builder: (dialogContext) {
        return AlertWithTwoActions(
            alertTitle: S.of(context).save_backup_password_alert,
            alertContent: S.of(context).change_backup_password_alert,
            rightButtonText: S.of(context).ok,
            leftButtonText: S.of(context).cancel,
            leftActionColor: Color(0xffFF6600),
            isDividerExist: true,
            rightActionColor: Theme.of(context).accentTextTheme.body2.color,
            actionRightButton: () async {
              Navigator.of(dialogContext)..pop()..pop();
            },
            actionLeftButton: () => Navigator.of(dialogContext).pop());
      });
}

class TipButtonGroup extends StatefulWidget {
  const TipButtonGroup({
    Key key,
  }) : super(key: key);

  @override
  _TipButtonGroupState createState() => _TipButtonGroupState();
}

class _TipButtonGroupState extends State<TipButtonGroup> {
  String selectedTip;
  bool _isSelected(String value) {
    return selectedTip == value;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TipButton(
          isSelected: _isSelected('299'),
          caption: '\$10',
          subTitle: '%299',
        ),
        SizedBox(width: 4),
        TipButton(
          caption: '\$10',
          subTitle: '%299',
        ),
        SizedBox(width: 4),
        TipButton(
          isSelected: _isSelected('299'),
          caption: '\$10',
          subTitle: '%299',
        ),
        SizedBox(width: 4),
        TipButton(
          isSelected: _isSelected('299'),
          caption: 'Custom',
        ),
      ],
    );
  }
}

class TipButton extends StatelessWidget {
  final String caption;
  final String subTitle;
  final bool isSelected;
  final void Function(int, bool) onTap;

  const TipButton({
    @required this.caption,
    this.subTitle,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 49,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(caption, style: textSmallSemiBold(color: Theme.of(context).primaryTextTheme.title.color)),
          if (subTitle != null) ...[
            SizedBox(height: 4),
            Text(
              subTitle,
              style: textXxSmallSemiBold(color: Palette.gray),
            ),
          ]
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Color.fromRGBO(242, 240, 250, 1),
        gradient: isSelected
            ? LinearGradient(
                colors: [
                  Theme.of(context).primaryTextTheme.subhead.color,
                  Theme.of(context).primaryTextTheme.subhead.decorationColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
      ),
    );
  }
}
