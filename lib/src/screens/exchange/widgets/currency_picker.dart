import 'package:flutter/material.dart';
import 'package:cake_wallet/src/screens/exchange/widgets/picker_item.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cake_wallet/src/widgets/picker.dart';
import 'package:cw_core/currency.dart';

class CurrencyPicker extends StatefulWidget {
  CurrencyPicker(
      {required this.selectedAtIndex,
      required this.items,
      required this.onItemSelected,
      this.title,
      this.hintText,
      this.isMoneroWallet = false,
      this.isConvertFrom = false});

  final int selectedAtIndex;
  final List<Currency> items;
  final String? title;
  final Function(Currency) onItemSelected;
  final bool isMoneroWallet;
  final bool isConvertFrom;
  final String? hintText;

  @override
  CurrencyPickerState createState() => CurrencyPickerState(items);
}

class CurrencyPickerState extends State<CurrencyPicker> {
  CurrencyPickerState(this.items)
      : isSearchBarActive = false,
        textFieldValue = '',
        appBarTextStyle = TextStyle(
            fontSize: 20,
            fontFamily: 'Lato',
            backgroundColor: Colors.transparent,
            color: Colors.white),
        pickerItemsList = <PickerItem<CryptoCurrency>>[];

  List<PickerItem<Currency>> pickerItemsList;
  List<Currency> items;
  bool isSearchBarActive;
  String textFieldValue;
  TextStyle appBarTextStyle;

  bool currencySearchBySubstring(Currency currency, String subString) {
    return currency.name.toLowerCase().contains(subString.toLowerCase()) ||
        (currency.tag != null
            ? currency.tag!.toLowerCase().contains(subString.toLowerCase())
            : false) ||
        (currency.fullName != null
            ? currency.fullName!.toLowerCase().contains(subString.toLowerCase())
            : false);
  }

  @override
  Widget build(BuildContext context) {
    return Picker(
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
