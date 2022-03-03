import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/sync_indicator_icon.dart';
import 'package:cake_wallet/src/screens/loan/widgets/loan_list_item.dart';
import 'package:cake_wallet/src/screens/loan/widgets/loan_login_section.dart';
import 'package:cake_wallet/src/widgets/keyboard_done_button.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:cake_wallet/view_model/loan/loan_account_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:keyboard_actions/keyboard_actions.dart';

class LoanAccountPage extends BasePage {
  LoanAccountPage({@required this.loanAccountViewModel})
      : _emailFocus = FocusNode(),
        _emailController = TextEditingController(),
        _codeFocus = FocusNode(),
        _codeController = TextEditingController();

  final LoanAccountViewModel loanAccountViewModel;

  final FocusNode _emailFocus;
  final TextEditingController _emailController;

  final FocusNode _codeFocus;
  final TextEditingController _codeController;

  @override
  String get title => 'Loan Account';

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
                  SyncIndicatorIcon(isSynced: loanAccountViewModel.status),
            ),
          ),
          super.middle(context),
        ],
      );
  @override
  Widget body(BuildContext context) {
    return KeyboardActions(
      config: KeyboardActionsConfig(
          keyboardActionsPlatform: KeyboardActionsPlatform.IOS,
          keyboardBarColor:
              Theme.of(context).accentTextTheme.body2.backgroundColor,
          nextFocus: false,
          actions: [
            KeyboardActionsItem(
              focusNode: _emailFocus,
              toolbarButtons: [(_) => KeyboardDoneButton()],
            ),
            KeyboardActionsItem(
              focusNode: _codeFocus,
              toolbarButtons: [(_) => KeyboardDoneButton()],
            ),
          ]),
      child: Container(
        height: 0,
        color: Theme.of(context).backgroundColor,
        child: ScrollableWithBottomSection(
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
                    SizedBox(height: 130),
                    Observer(builder: (_) {
                      final isLoggedIn = loanAccountViewModel.isLoggedIn;
                      if (isLoggedIn) return SizedBox(width: double.infinity);
                      return LoanLoginSection(
                        emailController: _emailController,
                        emailFocus: _emailFocus,
                        codeFocus: _codeFocus,
                        codeController: _codeController,
                      );
                    })
                  ],
                ),
              ),
              Column(
                children: [
                  SizedBox(height: 40),
                  LoanListItem(
                    textColor: textColor,
                    title: 'My Lending/Earning',
                    loginText: 'Log in above to lend',
                    loanAccountViewModel: loanAccountViewModel,
                    emptyListText: 'No open lendings/earnings yet',
                  ),
                  LoanListItem(
                    textColor: textColor,
                    title: 'My Borrowing',
                    loginText: 'Log in above to borrow with collateral',
                    emptyListText: 'No open loans yet',
                    loanAccountViewModel: loanAccountViewModel,
                  ),
                ],
              ),
            ],
          ),
          bottomSection: Observer(builder: (_) {
            return Column(
              children: [
                if (loanAccountViewModel.isLoggedIn) ...[
                  SizedBox(height: 20),
                  Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: PrimaryButton(
                      onPressed: () {},
                      text: 'Lend and Earn Interest',
                      color: Theme.of(context).accentTextTheme.body2.color,
                      textColor: Colors.white,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: PrimaryButton(
                      onPressed: () {},
                      text: ' Borrow with Collateral',
                      color: Theme.of(context).accentTextTheme.body2.color,
                      textColor: Colors.white,
                    ),
                  ),
                  SizedBox(height: 20),
                ] else
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      text: 'By logging in, you agree to the ',
                      style: TextStyle(color: Color(0xff7A93BA), fontSize: 12),
                      children: [
                        TextSpan(
                          text: 'Terms and Conditions',
                          style:
                              TextStyle(decoration: TextDecoration.underline),
                        ),
                        TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Privacy Policy of CoinRabbit',
                          style:
                              TextStyle(decoration: TextDecoration.underline),
                        )
                      ],
                    ),
                  ),
                SizedBox(height: 10)
              ],
            );
          }),
        ),
      ),
    );
  }
}
