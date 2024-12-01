import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:cake_wallet/cake_pay/cake_pay_card.dart';
import 'package:cake_wallet/cake_pay/cake_pay_payment_credantials.dart';
import 'package:cake_wallet/cake_pay/cake_pay_service.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/cake_pay/widgets/image_placeholder.dart';
import 'package:cake_wallet/src/screens/cake_pay/widgets/link_extractor.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/src/widgets/keyboard_done_button.dart';
import 'package:cake_wallet/src/widgets/number_text_fild_widget.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/themes/extensions/keyboard_theme.dart';
import 'package:cake_wallet/themes/extensions/send_page_theme.dart';
import 'package:cake_wallet/typography.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/cake_pay/cake_pay_buy_card_view_model.dart';
import 'package:cake_wallet/view_model/dashboard/dropdown_filter_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:keyboard_actions/keyboard_actions.dart';

class CakePayBuyCardPage extends BasePage {
  CakePayBuyCardPage(
    this.cakePayBuyCardViewModel,
    this.cakePayService,
  )   : _amountFieldFocus = FocusNode(),
        _amountController = TextEditingController(),
        _quantityFieldFocus = FocusNode(),
        _quantityController =
            TextEditingController(text: cakePayBuyCardViewModel.quantity.toString()) {
    _amountController.addListener(() {
      cakePayBuyCardViewModel.onAmountChanged(_amountController.text);
    });
  }

  final CakePayBuyCardViewModel cakePayBuyCardViewModel;
  final CakePayService cakePayService;

  @override
  String get title => cakePayBuyCardViewModel.card.name;

  @override
  bool get extendBodyBehindAppBar => true;

  @override
  AppBarStyle get appBarStyle => AppBarStyle.completelyTransparent;

  @override
  Widget? middle(BuildContext context) {
    return Text(
      title,
      textAlign: TextAlign.center,
      maxLines: 2,
      style: TextStyle(
          fontSize: 18.0,
          fontWeight: FontWeight.bold,
          fontFamily: 'Lato',
          color: titleColor(context)),
    );
  }

  final TextEditingController _amountController;
  final FocusNode _amountFieldFocus;
  final TextEditingController _quantityController;
  final FocusNode _quantityFieldFocus;

  @override
  Widget body(BuildContext context) {
    final card = cakePayBuyCardViewModel.card;
    final vendor = cakePayBuyCardViewModel.vendor;

    return KeyboardActions(
      disableScroll: true,
      config: KeyboardActionsConfig(
          keyboardActionsPlatform: KeyboardActionsPlatform.IOS,
          keyboardBarColor: Theme.of(context).extension<KeyboardTheme>()!.keyboardBarColor,
          nextFocus: false,
          actions: [
            KeyboardActionsItem(
              focusNode: _amountFieldFocus,
              toolbarButtons: [(_) => KeyboardDoneButton()],
            ),
          ]),
      child: Container(
        color: Theme.of(context).colorScheme.background,
        child: ScrollableWithBottomSection(
          contentPadding: EdgeInsets.zero,
          content: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(25.0), bottomRight: Radius.circular(25.0)),
                child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).extension<SendPageTheme>()!.firstGradientColor,
                          Theme.of(context).extension<SendPageTheme>()!.secondGradientColor,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    height: responsiveLayoutUtil.screenHeight * 0.35,
                    width: double.infinity,
                    child: Column(
                      children: [
                        Expanded(flex: 4, child: const SizedBox()),
                        Expanded(
                          flex: 7,
                          child: ClipRRect(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                            child: Image.network(
                              card.cardImageUrl ?? '',
                              fit: BoxFit.cover,
                              loadingBuilder: (BuildContext context, Widget child,
                                  ImageChunkEvent? loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(child: CircularProgressIndicator());
                              },
                              errorBuilder: (context, error, stackTrace) =>
                                  CakePayCardImagePlaceholder(),
                            ),
                          ),
                        ),
                        Expanded(child: const SizedBox()),
                      ],
                    )),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  height: responsiveLayoutUtil.screenHeight * 0.5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 24),
                      Expanded(
                        child: Text(S.of(context).enter_amount,
                            style: TextStyle(
                              color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                            )),
                      ),
                      card.denominations.isNotEmpty
                          ? Expanded(
                              flex: 2,
                              child: _DenominationsAmountWidget(
                                fiatCurrency: card.fiatCurrency.title,
                                denominations: card.denominations,
                                amountFieldFocus: _amountFieldFocus,
                                amountController: _amountController,
                                quantityFieldFocus: _quantityFieldFocus,
                                quantityController: _quantityController,
                                onAmountChanged: cakePayBuyCardViewModel.onAmountChanged,
                                onQuantityChanged: cakePayBuyCardViewModel.onQuantityChanged,
                                cakePayBuyCardViewModel: cakePayBuyCardViewModel,
                              ),
                            )
                          : Expanded(
                              flex: 2,
                              child: _EnterAmountWidget(
                                minValue: card.minValue ?? '-',
                                maxValue: card.maxValue ?? '-',
                                fiatCurrency: card.fiatCurrency.title,
                                amountFieldFocus: _amountFieldFocus,
                                amountController: _amountController,
                                onAmountChanged: cakePayBuyCardViewModel.onAmountChanged,
                              ),
                            ),
                      Expanded(
                        flex: 5,
                        child: Column(
                          children: [
                            if (vendor.cakeWarnings != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.white.withOpacity(0.20)),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      vendor.cakeWarnings!,
                                      textAlign: TextAlign.center,
                                      style: textSmallSemiBold(color: Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                            Expanded(
                              child: SingleChildScrollView(
                                child: ClickableLinksText(
                                  text: card.description ?? '',
                                  textStyle: TextStyle(
                                    color: Theme.of(context)
                                        .extension<CakeTextTheme>()!
                                        .secondaryTextColor,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomSection: Column(
            children: [
              Observer(builder: (_) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: PrimaryButton(
                    onPressed: () => isIOSUnavailable(card)
                        ? alertIOSAvailability(context, card)
                        : navigateToCakePayBuyCardDetailPage(context, card),
                    text: S.of(context).buy_now,
                    isDisabled: !cakePayBuyCardViewModel.isEnablePurchase,
                    color: Theme.of(context).primaryColor,
                    textColor: Colors.white,
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  bool isWordInCardsName(CakePayCard card, String word) {
    // word must be followed by a space or beginning of the string
    final regex = RegExp(r'(^|\s)' + word + r'(\s|$)', caseSensitive: false);

    return regex.hasMatch(card.name.toLowerCase());
  }

  bool isIOSUnavailable(CakePayCard card) {
    if (!Platform.isIOS) {
      return false;
    }

    final isDigitalGameStores = isWordInCardsName(card, 'playstation') ||
        isWordInCardsName(card, 'xbox') ||
        isWordInCardsName(card, 'steam') ||
        isWordInCardsName(card, 'meta quest') ||
        isWordInCardsName(card, 'kigso') ||
        isWordInCardsName(card, 'game world') ||
        isWordInCardsName(card, 'google') ||
        isWordInCardsName(card, 'nintendo');
    final isGCodes = isWordInCardsName(card, 'gcodes');
    final isApple = isWordInCardsName(card, 'itunes') || isWordInCardsName(card, 'apple');
    final isTidal = isWordInCardsName(card, 'tidal');
    final isVPNServices = isWordInCardsName(card, 'nordvpn') ||
        isWordInCardsName(card, 'expressvpn') ||
        isWordInCardsName(card, 'surfshark') ||
        isWordInCardsName(card, 'proton');
    final isStreamingServices = isWordInCardsName(card, 'netflix') ||
        isWordInCardsName(card, 'spotify') ||
        isWordInCardsName(card, 'hulu') ||
        isWordInCardsName(card, 'hbo') ||
        isWordInCardsName(card, 'soundcloud') ||
        isWordInCardsName(card, 'twitch');
    final isDatingServices = isWordInCardsName(card, 'tinder');

    return isDigitalGameStores ||
        isGCodes ||
        isApple ||
        isTidal ||
        isVPNServices ||
        isStreamingServices ||
        isDatingServices;
  }

  Future<void> alertIOSAvailability(BuildContext context, CakePayCard card) async {
    return await showPopUp<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertWithOneAction(
              alertTitle: S.of(context).error,
              alertContent: S.of(context).cakepay_ios_not_available,
              buttonText: S.of(context).ok,
              buttonAction: () {
                // _walletHardwareRestoreVM.error = null;
                Navigator.of(context).pop();
              });
        });
  }

  Future<void> navigateToCakePayBuyCardDetailPage(BuildContext context, CakePayCard card) async {
    final userName = await cakePayService.getUserEmail();
    final paymentCredential = PaymentCredential(
      amount: cakePayBuyCardViewModel.amount,
      quantity: cakePayBuyCardViewModel.quantity,
      totalAmount: cakePayBuyCardViewModel.totalAmount,
      userName: userName,
      fiatCurrency: card.fiatCurrency.title,
    );

    Navigator.pushNamed(
      context,
      Routes.cakePayBuyCardDetailPage,
      arguments: [paymentCredential, card],
    );
  }
}

class _DenominationsAmountWidget extends StatelessWidget {
  const _DenominationsAmountWidget({
    required this.fiatCurrency,
    required this.denominations,
    required this.amountFieldFocus,
    required this.amountController,
    required this.quantityFieldFocus,
    required this.quantityController,
    required this.cakePayBuyCardViewModel,
    required this.onAmountChanged,
    required this.onQuantityChanged,
  });

  final String fiatCurrency;
  final List<String> denominations;
  final FocusNode amountFieldFocus;
  final TextEditingController amountController;
  final FocusNode quantityFieldFocus;
  final TextEditingController quantityController;
  final CakePayBuyCardViewModel cakePayBuyCardViewModel;
  final Function(String) onAmountChanged;
  final Function(int?) onQuantityChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 12,
          child: Column(
            children: [
              Expanded(
                child: DropdownFilterList(
                  items: denominations,
                  itemPrefix: fiatCurrency,
                  selectedItem: denominations.first,
                  textStyle: textMediumSemiBold(
                      color: Theme.of(context).extension<CakeTextTheme>()!.titleColor),
                  onItemSelected: (value) {
                    amountController.text = value;
                    onAmountChanged(value);
                  },
                  caption: '',
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                          width: 1.0,
                          color: Theme.of(context).extension<CakeTextTheme>()!.secondaryTextColor),
                    ),
                  ),
                  child: Text(S.of(context).choose_card_value + ':',
                      maxLines: 2,
                      style: textSmall(
                          color: Theme.of(context).extension<CakeTextTheme>()!.secondaryTextColor)),
                ),
              ),
            ],
          ),
        ),
        Expanded(child: const SizedBox()),
        Expanded(
          flex: 8,
          child: Column(
            children: [
              Expanded(
                child: NumberTextField(
                  controller: quantityController,
                  focusNode: quantityFieldFocus,
                  min: 1,
                  max: 99,
                  onChanged: (value) => onQuantityChanged(value),
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                          width: 1.0,
                          color: Theme.of(context).extension<CakeTextTheme>()!.secondaryTextColor),
                    ),
                  ),
                  child: Text(S.of(context).quantity + ':',
                      maxLines: 1,
                      style: textSmall(
                          color: Theme.of(context).extension<CakeTextTheme>()!.secondaryTextColor)),
                ),
              ),
            ],
          ),
        ),
        Expanded(child: const SizedBox()),
        Expanded(
            flex: 12,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                      alignment: Alignment.bottomCenter,
                      child: Observer(
                          builder: (_) => AutoSizeText(
                              '$fiatCurrency ${cakePayBuyCardViewModel.totalAmount}',
                              maxLines: 1,
                              style: textMediumSemiBold(
                                  color:
                                      Theme.of(context).extension<CakeTextTheme>()!.titleColor)))),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                            width: 1.0,
                            color:
                                Theme.of(context).extension<CakeTextTheme>()!.secondaryTextColor),
                      ),
                    ),
                    child: Text(S.of(context).total + ':',
                        maxLines: 1,
                        style: textSmall(
                            color:
                                Theme.of(context).extension<CakeTextTheme>()!.secondaryTextColor)),
                  ),
                ),
              ],
            )),
      ],
    );
  }
}

class _EnterAmountWidget extends StatelessWidget {
  const _EnterAmountWidget({
    required this.minValue,
    required this.maxValue,
    required this.fiatCurrency,
    required this.amountFieldFocus,
    required this.amountController,
    required this.onAmountChanged,
  });

  final String minValue;
  final String maxValue;
  final String fiatCurrency;
  final FocusNode amountFieldFocus;
  final TextEditingController amountController;
  final Function(String) onAmountChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                  width: 1.0,
                  color: Theme.of(context).extension<CakeTextTheme>()!.secondaryTextColor),
            ),
          ),
          child: BaseTextFormField(
            controller: amountController,
            keyboardType: TextInputType.numberWithOptions(signed: false, decimal: true),
            hintText: '0.00',
            maxLines: null,
            borderColor: Colors.transparent,
            prefixIcon: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                '$fiatCurrency: ',
                style: textMediumSemiBold(
                    color: Theme.of(context).extension<CakeTextTheme>()!.titleColor),
              ),
            ),
            textStyle:
                textMediumSemiBold(color: Theme.of(context).extension<CakeTextTheme>()!.titleColor),
            placeholderTextStyle: textMediumSemiBold(
                color: Theme.of(context).extension<CakeTextTheme>()!.secondaryTextColor),
            inputFormatters: [
              FilteringTextInputFormatter.deny(RegExp('[\-|\ ]')),
              FilteringTextInputFormatter.allow(
                RegExp(r'^\d+(\.|\,)?\d{0,2}'),
              ),
            ],
          ),
        ),
        SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(S.of(context).min_amount(minValue) + ' $fiatCurrency',
                style: textSmall(
                    color: Theme.of(context).extension<CakeTextTheme>()!.secondaryTextColor)),
            Text(S.of(context).max_amount(maxValue) + ' $fiatCurrency',
                style: textSmall(
                    color: Theme.of(context).extension<CakeTextTheme>()!.secondaryTextColor)),
          ],
        ),
      ],
    );
  }
}
