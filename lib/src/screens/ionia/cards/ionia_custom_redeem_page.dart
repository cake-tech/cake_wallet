import 'package:cake_wallet/ionia/ionia_gift_card.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/ionia/widgets/card_item.dart';
import 'package:cake_wallet/src/widgets/keyboard_done_button.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:cake_wallet/typography.dart';
import 'package:cake_wallet/view_model/ionia/ionia_custom_redeem_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/generated/i18n.dart';


class IoniaCustomRedeemPage extends BasePage {
  IoniaCustomRedeemPage(
    this.viewModel,
  )   : _amountFieldFocus = FocusNode(),
        _amountController = TextEditingController() {
    _amountController.addListener(() {
      viewModel.onAmountChanged(_amountController.text);
    });
  }

  final IoniaCustomRedeemViewModel viewModel;

  @override
  Color get titleColor => Colors.white;

    @override
    Widget middle(BuildContext context) {
      return Text(
        S.of(context).custom_redeem_amount,
        textAlign: TextAlign.center,
        style: textMediumSemiBold(
          color: titleColor,), );
    }

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
    final IoniaGiftCard giftCard = viewModel.giftCard;
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 150),
                    BaseTextFormField(
                      controller: _amountController,
                      focusNode: _amountFieldFocus,
                      keyboardType: TextInputType.numberWithOptions(signed: false, decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.deny(RegExp('[\-|\ ]')),
                        WhitelistingTextInputFormatter(RegExp(r'^\d+(\.|\,)?\d{0,2}'))],
                      hintText: '1000',
                      placeholderTextStyle: TextStyle(
                        color: Theme.of(context).primaryTextTheme.headline.color,
                        fontWeight: FontWeight.w600,
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
                          'USD: ',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 36,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Observer(
                      builder: (_) => Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if(viewModel.isAmountAboveRemaining) 
                          Text(
                              S.of(context).amount_error,
                              style: TextStyle(
                                color: Theme.of(context).primaryTextTheme.headline.color,
                              ),
                            ),
                          if(!viewModel.isAmountAboveRemaining && viewModel.amount > 0)  
                          Text(
                            "\$${viewModel.giftCard.remainingAmount} - \$${viewModel.amount} = \$${viewModel.remaining} ' ' ${S.of(context).remaining}",
                            style: TextStyle(
                              color: Theme.of(context).primaryTextTheme.headline.color,
                            ),
                          ),   
                        ],
                      ),
                    ),
                    SizedBox(height: 24),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: CardItem(
                  title: giftCard.legalName,
                  backgroundColor: Theme.of(context).accentTextTheme.display4.backgroundColor.withOpacity(0.1),
                  discountText: '\$${giftCard.remainingAmount}',
                  discountBackground: AssetImage('assets/images/red_badge_discount.png'),
                  titleColor: Theme.of(context).accentTextTheme.display4.backgroundColor,
                  subtitleColor: Theme.of(context).hintColor,
                  subTitle: '',
                  logoUrl: giftCard.logoUrl,
                ),
              )
            ],
          ),
          bottomSection: Column(
            children: [
              Observer(builder: (_) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: PrimaryButton(
                    onPressed: () {},
                    text: S.of(context).add_custom_redemption,
                    isDisabled: viewModel.isAmountAboveRemaining,
                    color: Theme.of(context).accentTextTheme.body2.color,
                    textColor: Colors.white,
                  ),
                );
              }),
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
