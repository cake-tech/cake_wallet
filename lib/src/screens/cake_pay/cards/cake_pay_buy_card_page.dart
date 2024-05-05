import 'package:auto_size_text/auto_size_text.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/cake_pay/widgets/image_placeholder.dart';
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
import 'package:cake_wallet/view_model/cake_pay/cake_pay_buy_card_view_model.dart';
import 'package:cake_wallet/view_model/dashboard/dropdown_filter_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:keyboard_actions/keyboard_actions.dart';

class CakePayBuyCardPage extends BasePage {
  CakePayBuyCardPage(
    this.cakePayBuyCardViewModel,
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

  @override
  String get title => cakePayBuyCardViewModel.card.name;

  @override
  bool get extendBodyBehindAppBar => true;

  @override
  AppBarStyle get appBarStyle => AppBarStyle.completelyTransparent;

  final TextEditingController _amountController;
  final FocusNode _amountFieldFocus;
  final TextEditingController _quantityController;
  final FocusNode _quantityFieldFocus;

  @override
  Widget body(BuildContext context) {
    final card = cakePayBuyCardViewModel.card;

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
                borderRadius:
                    BorderRadius.horizontal(left: Radius.circular(20), right: Radius.circular(20)),
                child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).extension<SendPageTheme>()!.firstGradientColor,
                          Theme.of(context).extension<SendPageTheme>()!.secondGradientColor,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    height: responsiveLayoutUtil.screenHeight * 0.3,
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
                        child: SingleChildScrollView(
                          child: Text(
                            card.description ?? '',
                            style: TextStyle(
                              color: Theme.of(context).extension<CakeTextTheme>()!.secondaryTextColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
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
                    onPressed: () {
                      Navigator.pushNamed(context, Routes.cakePayBuyCardDetailPage, arguments: [
                        [
                          cakePayBuyCardViewModel.amount,
                          cakePayBuyCardViewModel.quantity.toDouble(),
                          cakePayBuyCardViewModel.totalAmount
                        ],
                        card,
                      ]);
                    },
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
                  child: Text('Choose a card value:', //TODO: S.of(context).choose_card_value,
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
                  child: Text('Quantity:', //TODO: S.of(context).quantity,
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
                    child: Text('Total:', //TODO: S.of(context).total,
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
