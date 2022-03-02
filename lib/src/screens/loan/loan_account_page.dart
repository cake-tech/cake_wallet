import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/action_button.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/sync_indicator_icon.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class LoanAccountPage extends BasePage {
  LoanAccountPage({Key key});
  @override
  String get title => 'Loan Account';

  @override
  Color get titleColor => Colors.white;

  @override
  bool get resizeToAvoidBottomInset => false;

  @override
  bool get extendBodyBehindAppBar => true;

  @override
  AppBarStyle get appBarStyle => AppBarStyle.transparent;

  Color get textColor =>
      currentTheme.type == ThemeType.dark ? Colors.white : Color(0xff393939);

  @override
  Widget middle(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: SyncIndicatorIcon(isSynced: false),
          ),
          super.middle(context),
        ],
      );
  @override
  Widget body(BuildContext context) {
    return ScrollableWithBottomSection(
      contentPadding: EdgeInsets.zero,
      content: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24)),
              gradient: LinearGradient(colors: [
                Theme.of(context).primaryTextTheme.subhead.color,
                Theme.of(context).primaryTextTheme.subhead.decorationColor,
              ], begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 150),
                SizedBox(
                  height: 40,
                  child: Row(
                    children: [
                      Expanded(
                        child: BaseTextFormField(
                          textColor: Colors.white,
                          hintText: 'Email OR Phone Number',
                          placeholderTextStyle:
                              TextStyle(color: Colors.white54),
                        ),
                      ),
                      SizedBox(
                        width: 90,
                        child: PrimaryButton(
                          onPressed: () {},
                          text: 'Get code',
                          color: Colors.white.withOpacity(0.2),
                          radius: 6,
                          textColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 37),
                SizedBox(
                  height: 40,
                  child: Row(
                    children: [
                      Expanded(
                        child: BaseTextFormField(
                          textColor: Colors.white,
                          hintText: 'SMS / Email Code',
                          placeholderTextStyle:
                              TextStyle(color: Colors.white54),
                        ),
                      ),
                      SizedBox(width: 10),
                      SizedBox(
                        width: 70,
                        child: PrimaryButton(
                            onPressed: () {},
                            text: 'Verify',
                            color: Colors.white.withOpacity(0.2),
                            radius: 6,
                            textColor: Colors.white),
                      ),
                      SizedBox(width: 10)
                    ],
                  ),
                ),
                SizedBox(height: 100),
              ],
            ),
          ),
          Column(
            children: [
              SizedBox(height: 40),
              Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                ),
                child: ExpansionTile(
                  initiallyExpanded: true,
                  trailing: Icon(
                    Icons.keyboard_arrow_down,
                    color: textColor,
                    size: 30,
                  ),
                  childrenPadding: EdgeInsets.symmetric(horizontal: 20),
                  title: Text(
                    'My Lending/Earning',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: textColor,
                      fontSize: 24,
                    ),
                  ),
                  children: [
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Text(
                        'Log in above to lend',
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          color: textColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 40),
              Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                ),
                child: ExpansionTile(
                  initiallyExpanded: true,
                  trailing: Icon(
                    Icons.keyboard_arrow_down,
                    color: textColor,
                    size: 30,
                  ),
                  childrenPadding: EdgeInsets.symmetric(horizontal: 20),
                  title: Text(
                    'My Borrowing',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: textColor,
                      fontSize: 24,
                    ),
                  ),
                  children: [
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Text(
                        'Log in above to borrow with collateral',
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          color: textColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Table(),
                  ],
                ),
              )
            ],
          ),
        ],
      ),
      bottomSection: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: PrimaryButton(
              onPressed: () {},
              text: 'Lend and Earn Interest',
              color: Theme.of(context).accentTextTheme.body2.color,
              textColor: Colors.white,
            ),
          ),
          SizedBox(height: 20),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              text: 'By logging in, you agree to the ',
              style: TextStyle(color: Color(0xff7A93BA), fontSize: 12),
              children: [
                TextSpan(
                  text: 'Terms and Conditions',
                  style: TextStyle(decoration: TextDecoration.underline),
                ),
                TextSpan(text: ' and '),
                TextSpan(
                  text: 'Privacy Policy of CoinRabbit',
                  style: TextStyle(decoration: TextDecoration.underline),
                )
              ],
            ),
          ),
          SizedBox(height: 10)
        ],
      ),
    );
  }
}

class Table extends StatelessWidget {
  const Table({Key key}) : super(key: key);

  Color get textColor =>
      getIt.get<SettingsStore>().currentTheme.type == ThemeType.dark
          ? Colors.white
          : Color(0xff393939);
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'ID',
                  style: TextStyle(color: textColor),
                ),
              ),
              Expanded(
                child: Text(
                  'Amount',
                  style: TextStyle(color: textColor),
                ),
              ),
              Expanded(
                child: Text(
                  'Status',
                  style: TextStyle(color: textColor),
                ),
              ),
              SizedBox(width: 25),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Color(0xffF1EDFF),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '5395821325',
                  style: TextStyle(color: textColor),
                ),
              ),
              Expanded(
                child: Text(
                  '10000 USDT',
                  style: TextStyle(color: textColor),
                ),
              ),
              Expanded(
                child: Text(
                  'Awaiting deposit',
                  style: TextStyle(color: textColor),
                ),
              ),
              Icon(Icons.chevron_right)
            ],
          ),
        ),
        SizedBox(height: 10),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Color(0xffF1EDFF),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '5395821325',
                  style: TextStyle(color: textColor),
                ),
              ),
              Expanded(
                child: Text(
                  '10000 USDT',
                  style: TextStyle(color: textColor),
                ),
              ),
              Expanded(
                child: Text(
                  'Awaiting deposit',
                  style: TextStyle(color: textColor),
                ),
              ),
              Icon(Icons.chevron_right)
            ],
          ),
        ),
        SizedBox(height: 10),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Color(0xffF1EDFF),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '5395821325',
                  style: TextStyle(color: textColor),
                ),
              ),
              Expanded(
                child: Text(
                  '10000 USDT',
                  style: TextStyle(color: textColor),
                ),
              ),
              Expanded(
                child: Text(
                  'Awaiting deposit',
                  style: TextStyle(color: textColor),
                ),
              ),
              Icon(Icons.chevron_right)
            ],
          ),
        ),
      ],
    );
  }
}
