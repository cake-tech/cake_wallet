import 'package:cake_wallet/ionia/ionia_merchant.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/ionia/widgets/card_item.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/src/widgets/keyboard_done_button.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:cake_wallet/generated/i18n.dart';

class IoniaBuyGiftCardPage extends BasePage {
  IoniaBuyGiftCardPage(this.merchant)
      : _amountFieldFocus = FocusNode(),
        _amountController = TextEditingController();

  final IoniaMerchant merchant;

  @override
  String get title => S.current.enter_amount;

  @override
  Color get titleColor => Colors.white;

  @override
  bool get extendBodyBehindAppBar => true;

  @override
  AppBarStyle get appBarStyle => AppBarStyle.transparent;

  Color get textColor => currentTheme.type == ThemeType.dark ? Colors.white : Color(0xff393939);

  final TextEditingController _amountController;
  final FocusNode _amountFieldFocus;

  @override
  Widget body(BuildContext context) {
    final _width = MediaQuery.of(context).size.width;
    return KeyboardActions(
      disableScroll: true,
      config: KeyboardActionsConfig(
          keyboardActionsPlatform: KeyboardActionsPlatform.IOS,
          keyboardBarColor: Theme.of(context).accentTextTheme.body2.backgroundColor,
          nextFocus: false,
          actions: [
            KeyboardActionsItem(
              focusNode: _amountFieldFocus,
              toolbarButtons: [(_) => KeyboardDoneButton()],
            ),
          ]),
      child: Container(
        color: Theme.of(context).backgroundColor,
        child: ScrollableWithBottomSection(
          contentPadding: EdgeInsets.zero,
          content: Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 25),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
                  gradient: LinearGradient(colors: [
                    Theme.of(context).primaryTextTheme.subhead.color,
                    Theme.of(context).primaryTextTheme.subhead.decorationColor,
                  ], begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 150),
                    BaseTextFormField(
                      controller: _amountController,
                      focusNode: _amountFieldFocus,
                      keyboardType: TextInputType.numberWithOptions(signed: false, decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.deny(RegExp('[\-|\ ]'))],
                      hintText: '1000',
                      placeholderTextStyle: TextStyle(
                        color: Theme.of(context).primaryTextTheme.headline.color,
                        fontWeight: FontWeight.w500,
                        fontSize: 36,
                      ),
                      borderColor: Theme.of(context).primaryTextTheme.headline.color,
                      textColor: Colors.white,
                      textStyle: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                      ),
                      suffixIcon: SizedBox(
                        width: _width / 6,
                      ),
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(
                          top: 5.0,
                          left: _width / 4,
                        ),
                        child: Text(
                          '${merchant.acceptedCurrency}: ',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 36,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          S.of(context).min_amount(merchant.minimumCardPurchase.toString()),
                          style: TextStyle(
                            color: Theme.of(context).primaryTextTheme.headline.color,
                          ),
                        ),
                        Text(
                          S.of(context).max_amount(merchant.maximumCardPurchase.toString()),
                          style: TextStyle(
                            color: Theme.of(context).primaryTextTheme.headline.color,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: CardItem(
                  title: merchant.legalName,
                  backgroundColor: Theme.of(context).accentTextTheme.display4.backgroundColor.withOpacity(0.1),
                  discount: 0.0,
                  titleColor: Theme.of(context).accentTextTheme.display4.backgroundColor,
                  subtitleColor: Theme.of(context).hintColor,
                  subTitle: merchant.isOnline ? S.of(context).online : S.of(context).offline,
                  logoUrl: merchant.logoUrl,
                ),
              )
            ],
          ),
          bottomSection: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: PrimaryButton(
                  onPressed: () => Navigator.of(context).pushNamed(Routes.ioniaBuyGiftCardDetailPage, arguments: [merchant] ),
                  text: S.of(context).continue_text,
                  color: Theme.of(context).accentTextTheme.body2.color,
                  textColor: Theme.of(context).primaryTextTheme.body1.color,
                ),
              ),
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
