import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/loan/widgets/loan_detail_tile.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/src/widgets/keyboard_done_button.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:cake_wallet/view_model/loan/loan_detail_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:keyboard_actions/keyboard_actions.dart';

class IncreaseDeposit extends BasePage {
  IncreaseDeposit({this.loanDetailViewModel})
      : _amountFocus = FocusNode(),
        _amountController = TextEditingController();

  final LoanDetailViewModel loanDetailViewModel;
  final FocusNode _amountFocus;
  final TextEditingController _amountController;

  @override
  String get title => 'Increase deposit';

  @override
  Color get titleColor => Colors.white;

  @override
  bool get extendBodyBehindAppBar => true;

  @override
  AppBarStyle get appBarStyle => AppBarStyle.transparent;

  Color get textColor =>
      currentTheme.type == ThemeType.dark ? Colors.white : Color(0xff393939);

  @override
  Widget middle(BuildContext context) => Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontFamily: 'Poppins',
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
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
              focusNode: _amountFocus,
              toolbarButtons: [(_) => KeyboardDoneButton()],
            ),
          ]),
      child: SizedBox(
        height: 0,
        child: ScrollableWithBottomSection(
          contentPadding: EdgeInsets.zero,
          content: Column(
            children: [
              Container(
                padding: EdgeInsets.only(bottom: 20),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    width: 160,
                    child: BaseTextFormField(
                      controller: _amountController,
                      focusNode: _amountFocus,
                      keyboardType: TextInputType.numberWithOptions(
                          signed: false, decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.deny(RegExp('[\\-|\\ ]'))
                      ],
                      hintText: '0.0000',
                      placeholderTextStyle: TextStyle(
                        color:
                            Theme.of(context).primaryTextTheme.headline.color,
                        fontSize: 36,
                      ),
                      borderColor:
                          Theme.of(context).primaryTextTheme.headline.color,
                      textColor: Colors.white,
                      textStyle: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                      ),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(top: 5.0),
                        child: Text(
                          'XMR: ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                height: 180,
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
                child: IncreaseDepositContent(),
              )
            ],
          ),
          bottomSection: Column(
            children: [
              SizedBox(height: 20),
              Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: PrimaryButton(
                  onPressed: () => Navigator.of(context)
                      .pushNamed(Routes.confirmDepositPage),
                  text: 'Confirm',
                  color: Theme.of(context).accentTextTheme.body2.color,
                  textColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class IncreaseDepositContent extends StatelessWidget {
  const IncreaseDepositContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LoanDetailTile(
          title: 'Liquidation price will become',
          trailing: '101.53 XMR/USDT',
        ),
        SizedBox(height: 30),
        LoanDetailTile(
          title: 'Buffer',
          subtitle:
              'How much XMR must fall in relation to USDT before liquidation',
          trailing: '44.8% -> 72.1%',
        ),
      ],
    );
  }
}
