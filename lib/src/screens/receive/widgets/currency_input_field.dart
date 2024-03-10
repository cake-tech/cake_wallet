import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/currency.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cake_wallet/themes/extensions/dashboard_page_theme.dart';
import 'package:cake_wallet/themes/extensions/picker_theme.dart';
import 'package:cake_wallet/themes/extensions/send_page_theme.dart';

class CurrencyInputField extends StatelessWidget {
  const CurrencyInputField({
    super.key,
    required this.onTapPicker,
    required this.selectedCurrency,
    this.focusNode,
    required this.controller,
    required this.isLight,
  });

  final Function() onTapPicker;
  final Currency selectedCurrency;
  final FocusNode? focusNode;
  final TextEditingController controller;
  final bool isLight;

  String get _currencyName {
    if (selectedCurrency is CryptoCurrency) {
      return (selectedCurrency as CryptoCurrency).title.toUpperCase();
    }
    return selectedCurrency.name.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final arrowBottomPurple = Image.asset(
      'assets/images/arrow_bottom_purple_icon.png',
      color: Theme.of(context).extension<DashboardPageTheme>()!.textColor,
      height: 8,
    );
    // This magic number for wider screen sets the text input focus at center of the inputfield
    final _width =
        responsiveLayoutUtil.shouldRenderMobileUI ? MediaQuery.of(context).size.width : 500;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(top: 20),
          child: SizedBox(
            height: 40,
            child: BaseTextFormField(
              focusNode: focusNode,
              controller: controller,
              keyboardType: TextInputType.numberWithOptions(signed: false, decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+(\.|\,)?\d{0,8}'))],
              hintText: '0.000',
              placeholderTextStyle: isLight
                  ? null
                  : TextStyle(
                      color: Theme.of(context).extension<SendPageTheme>()!.textFieldBorderColor,
                      fontWeight: FontWeight.w600,
                    ),
              borderColor: Theme.of(context).extension<PickerTheme>()!.dividerColor,
              textColor: Theme.of(context).extension<DashboardPageTheme>()!.textColor,
              textStyle: TextStyle(
                color: Theme.of(context).extension<DashboardPageTheme>()!.textColor,
              ),
              prefixIcon: Padding(
                padding: EdgeInsets.only(
                  left: _width / 4,
                ),
                child: Container(
                  padding: EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: onTapPicker,
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Padding(
                            padding: EdgeInsets.only(right: 5),
                            child: arrowBottomPurple,
                          ),
                          Text(
                            _currencyName,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Theme.of(context).extension<DashboardPageTheme>()!.textColor,
                            ),
                          ),
                          if (selectedCurrency.tag != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).extension<SendPageTheme>()!.textFieldButtonColor,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(6),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    selectedCurrency.tag!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).extension<SendPageTheme>()!.textFieldButtonIconColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 3.0),
                            child: Text(
                              ':',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 20,
                                color: Theme.of(context).extension<DashboardPageTheme>()!.textColor,
                              ),
                            ),
                          ),
                        ]),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
