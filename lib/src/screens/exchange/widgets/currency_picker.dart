import 'dart:ui';
import 'package:cake_wallet/src/screens/exchange/widgets/currency_picker_item_widget.dart';
import 'package:cake_wallet/src/screens/exchange/widgets/picker_item.dart';
import 'package:cake_wallet/src/widgets/alert_close_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cake_wallet/src/widgets/alert_background.dart';
import 'package:cake_wallet/palette.dart';
import 'currency_picker_widget.dart';

class CurrencyPicker extends StatefulWidget {
  CurrencyPicker(
      {required this.selectedAtIndex,
      required this.items,
      required this.onItemSelected,
      this.title,
      this.hintText,
      this.isMoneroWallet = false,
      this.isConvertFrom = false});

  int selectedAtIndex;
  final List<CryptoCurrency> items;
  final String? title;
  final Function(CryptoCurrency) onItemSelected;
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
        subPickerItemsList = items,
        appBarTextStyle =
          TextStyle(fontSize: 20, fontFamily: 'Lato', backgroundColor: Colors.transparent, color: Colors.white),
        pickerItemsList = <PickerItem<CryptoCurrency>>[];

  List<PickerItem<CryptoCurrency>> pickerItemsList;
  List<CryptoCurrency> items;
  bool isSearchBarActive;
  String textFieldValue;
  List<CryptoCurrency> subPickerItemsList;
  TextStyle appBarTextStyle;

  void cleanSubPickerItemsList() => subPickerItemsList = items;

  void currencySearchBySubstring(String subString) {
    setState(() {
      if (subString.isNotEmpty) {
        subPickerItemsList = items
            .where((element) =>
        (element.title != null ? element.title.toLowerCase().contains(subString.toLowerCase()) : false) ||
            (element.tag != null ? element.tag!.toLowerCase().contains(subString.toLowerCase()) : false) ||
            (element.fullName != null ? element.fullName!.toLowerCase().contains(subString.toLowerCase()) : false))
            .toList();
        return;
      }
      cleanSubPickerItemsList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertBackground(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (widget.title?.isNotEmpty ?? false)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    widget.title!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'Lato',
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none,
                      color: Colors.white,
                    ),
                  ),
                ),
              Padding(
                padding: EdgeInsets.only(left: 24, right: 24, top: 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(30)),
                  child: Container(
                    color: Theme.of(context).accentTextTheme!.headline6!.color!,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.65,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.hintText != null)
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: TextFormField(
                                style: TextStyle(color: Palette.darkBlueCraiola),
                                decoration: InputDecoration(
                                  hintText: widget.hintText,
                                  prefixIcon: Image.asset("assets/images/search_icon.png"),
                                  filled: true,
                                  fillColor: const Color(0xffF2F0FA),
                                  alignLabelWithHint: false,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                                  enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                        color: Colors.transparent,
                                      )),
                                  focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                        color: Colors.transparent,
                                      )),
                                ),
                                onChanged: (value) {
                                  this.textFieldValue = value;
                                  cleanSubPickerItemsList();
                                  currencySearchBySubstring(textFieldValue);
                                },
                              ),
                            ),
                          Divider(
                            color: Theme.of(context).accentTextTheme!.headline6!.backgroundColor!,
                            height: 1,
                          ),
                          if (widget.selectedAtIndex != -1)
                            AspectRatio(
                              aspectRatio: 6,
                              child: PickerItemWidget(
                                title: items[widget.selectedAtIndex].title,
                                iconPath: items[widget.selectedAtIndex].iconPath,
                                isSelected: true,
                                tag: items[widget.selectedAtIndex].tag,
                              ),
                            ),
                          Flexible(
                            child: CurrencyPickerWidget(
                              crossAxisCount: 2,
                              selectedAtIndex: widget.selectedAtIndex,
                              pickerItemsList: subPickerItemsList,
                              pickListItem: (int index) {
                                setState(() {
                                  widget.selectedAtIndex = index;
                                });
                                widget.onItemSelected(subPickerItemsList[index]);
                                if (widget.isConvertFrom &&
                                    !widget.isMoneroWallet &&
                                    (subPickerItemsList[index] == CryptoCurrency.xmr)) {
                                } else {
                                  Navigator.of(context).pop();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          AlertCloseButton(),
        ],
      ),
    );
  }
}
