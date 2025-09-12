import 'package:flutter/material.dart';
import 'package:cake_wallet/src/screens/exchange/widgets/picker_item.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cake_wallet/src/widgets/picker.dart';
import 'package:cw_core/currency.dart';
import 'package:cake_wallet/themes/core/material_base_theme.dart';

class CurrencyPicker extends StatefulWidget {
  CurrencyPicker(
      {required this.selectedAtIndex,
      required this.items,
      required this.onItemSelected,
      this.title,
      this.hintText,
      this.isMoneroWallet = false,
      this.isConvertFrom = false,
      required this.currentTheme,
      super.key});

  final int selectedAtIndex;
  final List<Currency> items;
  final String? title;
  final Function(Currency) onItemSelected;
  final bool isMoneroWallet;
  final bool isConvertFrom;
  final String? hintText;
  final MaterialThemeBase currentTheme;
  
  @override
  CurrencyPickerState createState() => CurrencyPickerState(items);
}

class CurrencyPickerState extends State<CurrencyPicker> {
  CurrencyPickerState(this.items)
      : isSearchBarActive = false,
        textFieldValue = '',
        pickerItemsList = <PickerItem<CryptoCurrency>>[];

  List<PickerItem<Currency>> pickerItemsList;
  List<Currency> items;
  bool isSearchBarActive;
  String textFieldValue;

  bool currencySearchBySubstring(Currency currency, String subString) {
    final query = subString.toLowerCase();
    return currency.name.toLowerCase().contains(query) ||
        currency.toString().toLowerCase().contains(query) ||
        (currency.tag != null ? currency.tag!.toLowerCase().contains(query) : false) ||
        (currency.fullName != null ? currency.fullName!.toLowerCase().contains(query) : false);
  }

  @override
  Widget build(BuildContext context) {
    return Picker(
      currentTheme: widget.currentTheme,
      selectedAtIndex: widget.selectedAtIndex,
      items: items,
      isGridView: true,
      title: widget.title,
      hintText: widget.hintText,
      matchingCriteria: currencySearchBySubstring,
      onItemSelected: widget.onItemSelected,
    );
  }
}
