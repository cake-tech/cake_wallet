import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/keyboard_done_button.dart';
import 'package:cake_wallet/src/widgets/number_text_fild_widget.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/themes/extensions/keyboard_theme.dart';
import 'package:cake_wallet/themes/extensions/picker_theme.dart';
import 'package:cake_wallet/themes/extensions/send_page_theme.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:cake_wallet/view_model/dashboard/dropdown_filter_item_widget.dart';
import 'package:cake_wallet/view_model/ionia/ionia_buy_card_view_model.dart';
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
        _quantityController = TextEditingController() {
    _amountController.addListener(() {
      cakePayBuyCardViewModel.onAmountChanged(_amountController.text);
    });
  }

  final CakePayBuyCardViewModel cakePayBuyCardViewModel;

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
              Container(
                  height: responsiveLayoutUtil.screenHeight * 0.3,
                  child: ClipRRect(
                    borderRadius: BorderRadius.horizontal(
                        left: Radius.circular(20), right: Radius.circular(20)),
                    child: Image.network(
                      card.cardImageUrl ?? '',
                      fit: BoxFit.cover,
                      loadingBuilder:
                          (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) =>
                          _PlaceholderContainer(text: 'Logo not found!'),
                    ),
                  )),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(card.name ?? '',
                        style: TextStyle(
                          color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        )),
                    SizedBox(height: 36),
                    card.denominations.isNotEmpty
                        ? _DenominationsAmountWidget(
                            fiatCurrency: card.fiatCurrency.title ?? '',
                            denominations: card.denominations,
                            amountFieldFocus: _amountFieldFocus,
                            amountController: _amountController,
                            quantityFieldFocus: _quantityFieldFocus,
                            quantityController: _quantityController,
                            onAmountChanged: cakePayBuyCardViewModel.onAmountChanged,
                          )
                        : _EnterAmountWidget(
                            minValue: card.minValue ?? '-',
                            maxValue: card.maxValue ?? '-',
                            fiatCurrency: card.fiatCurrency.title ?? '',
                            amountFieldFocus: _amountFieldFocus,
                            amountController: _amountController,
                            onAmountChanged: cakePayBuyCardViewModel.onAmountChanged,
                          ),
                    SizedBox(height: 20),
                    Text(
                      card.description ?? '',
                      style: TextStyle(
                        color: Theme.of(context).extension<CakeTextTheme>()!.secondaryTextColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
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
                        cakePayBuyCardViewModel.amount,
                        card,
                      ]);
                    },
                    text: 'Buy Now',
                    //TODO: S.of(context).buy_now,
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
    required this.onAmountChanged,
  });

  final String fiatCurrency;
  final List<String> denominations;
  final FocusNode amountFieldFocus;
  final TextEditingController amountController;
  final FocusNode quantityFieldFocus;
  final TextEditingController quantityController;
  final Function(String) onAmountChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Choose a card value below:', //TODO: S.of(context).choose_card_value,
                style: TextStyle(
                  color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
                  fontSize: 14,
                )),
            Text('Quantity:', //TODO: S.of(context).quantity,
                style: TextStyle(
                  color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
                  fontSize: 14,
                )),
          ],
        ),
        SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 3,
              child: DropdownFilterList(
                items: denominations,
                selectedItem: denominations.first,
                onItemSelected: (value) {
                  amountController.text = value;
                  onAmountChanged(value);
                },
                caption: '',
              ),
            ),
            Expanded(
              child: NumberTextField(
                controller: amountController,
                focusNode: amountFieldFocus,
                min: 0,
                max: 999,
                onChanged: (value) {
                  onAmountChanged(value.toString());
                },
              ),
            ),
          ],
        )
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(S.of(context).enter_amount,
                style: TextStyle(
                  color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
                  fontSize: 14,
                )),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(S.of(context).min_amount(minValue) + ' $fiatCurrency',
                    style: TextStyle(
                      color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
                      fontSize: 14,
                    )),
                SizedBox(width: 10),
                Text(S.of(context).max_amount(maxValue) + ' $fiatCurrency',
                    style: TextStyle(
                      color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
                      fontSize: 14,
                    )),
              ],
            ),
          ],
        ),
        SizedBox(height: 4),
        TextField(
          focusNode: amountFieldFocus,
          style: TextStyle(
              color: Theme.of(context).extension<PickerTheme>()!.searchHintColor,
              fontWeight: FontWeight.w600,
              fontSize: 24),
          controller: amountController,
          keyboardType: TextInputType.numberWithOptions(signed: false, decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.deny(RegExp('[\-|\ ]')),
            FilteringTextInputFormatter.allow(
              RegExp(r'^\d+(\.|\,)?\d{0,2}'),
            ),
          ],
          decoration: InputDecoration(
            filled: true,
            contentPadding: EdgeInsets.only(
              top: 10,
              left: 10,
            ),
            fillColor: Theme.of(context).extension<PickerTheme>()!.searchBackgroundFillColor,
            alignLabelWithHint: true,
            floatingLabelBehavior: FloatingLabelBehavior.never,
            prefixIcon: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                fiatCurrency,
                style: TextStyle(
                  color: Theme.of(context).extension<PickerTheme>()!.searchHintColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 24,
                ),
              ),
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.2),
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: Theme.of(context).extension<PickerTheme>()!.searchBorderColor ??
                      Colors.transparent,
                )),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Colors.transparent,
                )),
          ),
        ),
      ],
    );
  }
}

class _PlaceholderContainer extends StatelessWidget {
  const _PlaceholderContainer({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: Theme.of(context).extension<PickerTheme>()!.searchHintColor,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          Theme.of(context).extension<SendPageTheme>()!.firstGradientColor,
          Theme.of(context).extension<SendPageTheme>()!.secondGradientColor,
        ], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
    );
  }
}
