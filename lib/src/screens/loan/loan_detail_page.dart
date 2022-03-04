import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/sync_indicator_icon.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:cake_wallet/view_model/loan/loan_detail_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class LoanDetailPage extends BasePage {
  LoanDetailPage({this.loanDetailViewModel});

  final LoanDetailViewModel loanDetailViewModel;

  @override
  String get title => 'Loan ${loanDetailViewModel.loanDetails.id}';

  @override
  Color get titleColor => Colors.white;

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
            child: Observer(
              builder: (_) =>
                  SyncIndicatorIcon(isSynced: loanDetailViewModel.status),
            ),
          ),
          Text(
            title,
            style: TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
                fontSize: 22,
                fontWeight: FontWeight.w600),
          ),
        ],
      );

  @override
  Widget body(BuildContext context) {
    return ScrollableWithBottomSection(
      contentPadding: EdgeInsets.zero,
      content: Column(
        children: [
          Container(
            height: 130,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24)),
              gradient: LinearGradient(colors: [
                Theme.of(context).primaryTextTheme.subhead.color,
                Theme.of(context).primaryTextTheme.subhead.decorationColor,
              ], begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
          ),
          SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: LoanContent(),
          )
        ],
      ),
      bottomSection: Column(
        children: [
          SizedBox(height: 20),
          Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: PrimaryButton(
              onPressed: () {},
              text: 'Increase Deposit',
              color: Theme.of(context).accentTextTheme.body2.color,
              textColor: Colors.white,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: PrimaryButton(
              onPressed: () {},
              text: 'Repay Desposit and Close',
              color: Theme.of(context).accentTextTheme.body2.color,
              textColor: Colors.white,
            ),
          ),
          if (!loanDetailViewModel.isLoan)
            Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: PrimaryButton(
                onPressed: () {},
                text: 'Withdraw and Close',
                color: Theme.of(context).accentTextTheme.body2.color,
                textColor: Colors.white,
              ),
            ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}

class LendContent extends StatelessWidget {
  const LendContent({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LoanDetailItem(
          title: 'Initial deposit',
          trailing: '101.53 USDT',
        ),
        SizedBox(height: 30),
        LoanDetailItem(
          title: 'Earned interest',
          trailing: '101.53 USDT',
        ),
        SizedBox(height: 30),
        LoanDetailItem(
          title: 'Current value',
          trailing: '101.53 USDT',
        ),
        SizedBox(height: 30),
        LoanDetailItem(
          title: 'Interest value',
          trailing: '12.23% APY',
        ),
      ],
    );
  }
}

class LoanContent extends StatelessWidget {
  const LoanContent({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LoanDetailItem(
          title: 'You got',
          trailing: '101.53 USDT',
        ),
        SizedBox(height: 30),
        LoanDetailItem(
          title: 'Your deposit',
          trailing: '101.53 USDT',
        ),
        SizedBox(height: 30),
        LoanDetailItem(
          title: 'Repayment',
          trailing: '101.53 USDT',
        ),
        SizedBox(height: 30),
        LoanDetailItem(
          title: 'Market price',
          trailing: '1,779.42 XMR/USDT',
        ),
        SizedBox(height: 30),
        LoanDetailItem(
          title: 'Liquidation price',
          trailing: '1,779.42 XMR/USDT',
        ),
        SizedBox(height: 30),
        LoanDetailItem(
          title: 'Buffer',
          subtitle:
              'How much XMR must fall in relation to USDT before liquidation',
          trailing: '44.8%',
        ),
      ],
    );
  }
}

class LoanDetailItem extends StatelessWidget {
  LoanDetailItem({
    @required this.title,
    this.subtitle,
    @required this.trailing,
  });

  final String title;
  final String subtitle;
  final String trailing;

  ThemeBase get currentTheme => getIt.get<SettingsStore>().currentTheme;

  Color get textColor =>
      currentTheme.type == ThemeType.dark ? Colors.white : Color(0xff393939);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: textColor,
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle != null
                ? SizedBox(
                    width: 200,
                    child: Text(
                      subtitle,
                      style: TextStyle(
                        color: textColor,
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  )
                : SizedBox.shrink(),
          ],
        ),
        Text(
          trailing,
          style: TextStyle(
            color: textColor,
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
