import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:cw_core/currency.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  @override
  Widget build(BuildContext context) {
    final arrowBottomPurple = Image.asset(
      'assets/images/arrow_bottom_purple_icon.png',
      color: Theme.of(context).accentTextTheme!.displayMedium!.backgroundColor!,
      height: 8,
    );
    // This magic number for wider screen sets the text input focus at center of the inputfield
    final _width =
        ResponsiveLayoutUtil.instance.isMobile ? MediaQuery.of(context).size.width : 500;

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
                      color: Theme.of(context).primaryTextTheme!.headlineSmall!.color!,
                      fontWeight: FontWeight.w600,
                    ),
              borderColor: Theme.of(context).accentTextTheme!.titleLarge!.backgroundColor!,
              textColor: Theme.of(context).accentTextTheme!.displayMedium!.backgroundColor!,
              textStyle: TextStyle(
                color: Theme.of(context).accentTextTheme!.displayMedium!.backgroundColor!,
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
                            selectedCurrency.name.toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Theme.of(context)
                                  .accentTextTheme!
                                  .displayMedium!
                                  .backgroundColor!,
                            ),
                          ),
                          if (selectedCurrency.tag != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 3.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryTextTheme!.headlineMedium!.color!,
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
                                      color: Theme.of(context)
                                          .primaryTextTheme!
                                          .headlineMedium!
                                          .decorationColor!,
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
                                color: Theme.of(context)
                                    .accentTextTheme!
                                    .displayMedium!
                                    .backgroundColor!,
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
