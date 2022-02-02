import 'dart:ui';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/src/screens/exchange/widgets/picker_Item.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cake_wallet/src/widgets/alert_background.dart';
import 'currency_picker_widget.dart';

class CurrencyPicker extends StatefulWidget {
  CurrencyPicker({
    @required this.selectedAtIndex,
    @required this.items,
    @required this.title,
    @required this.onItemSelected,
  });

  int selectedAtIndex;
  final List<CryptoCurrency> items;
  final String title;
  final Function onItemSelected;

  @override
  CurrencyPickerState createState() => CurrencyPickerState(items);
}

class CurrencyPickerState extends State<CurrencyPicker> {
  CurrencyPickerState(this.items)
      : itemsCount = items.length,
        isSearchBarActive = false,
        textFieldValue = '',
        subCryptoCurrencyList = [],
        appBarTextStyle = TextStyle(
            fontSize: 20,
            fontFamily: 'Lato',
            backgroundColor: Colors.transparent,
            color: Colors.white);

  List<CryptoCurrency> items;
  int itemsCount;
  bool isSearchBarActive;
  String textFieldValue;
  List<CryptoCurrency> subCryptoCurrencyList;
  TextStyle appBarTextStyle;

  void currencySearchBySubstring(String subString, List<CryptoCurrency> list) {
    subCryptoCurrencyList = [];
    setState(() {
      if (subString.isEmpty) {
        itemsCount = list.length;
      } else {
        items.forEach((element) {
          if (element.title.contains(subString.toUpperCase()) ||
              PickerItem(currencyIndex: element.raw)
                  .currencyName
                  .contains(subString.toLowerCase())) {
            subCryptoCurrencyList.add(element);
          }
        });
        itemsCount = subCryptoCurrencyList.length;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertBackground(
      child: SafeArea(
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 26.0, vertical: 0),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      isSearchBarActive
                          ? Expanded(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  InkWell(
                                      child: Text(
                                        S.of(context).cancel,
                                        style: appBarTextStyle,
                                      ),
                                      onTap: () {
                                        setState(() {
                                          isSearchBarActive = false;
                                          textFieldValue = '';
                                          itemsCount = items.length;
                                        });
                                      }),
                                  Container(
                                    width: 100.0,
                                    child: CupertinoTextField(
                                        autofocus: true,
                                        placeholder:
                                            S.of(context).search + '...',
                                        placeholderStyle: appBarTextStyle,
                                        decoration: BoxDecoration(
                                            color: Colors.transparent),
                                        cursorColor: Colors.white,
                                        cursorHeight: 23.0,
                                        style: appBarTextStyle,
                                        onChanged: (value) {
                                          this.textFieldValue = value;
                                          currencySearchBySubstring(
                                              textFieldValue, widget.items);
                                        }),
                                  )
                                ],
                              ),
                            )
                          : Text(
                              widget.title,
                              style: appBarTextStyle,
                            ),
                      IconButton(
                        splashRadius: 23,
                        icon: Icon(Icons.search, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            isSearchBarActive = true;
                          });
                        },
                      )
                    ]),
              ),
              Expanded(
                flex: 12,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 26.0, vertical: 26.0),
                  child: Container(
                    child: CurrencyPickerWidget(
                      textFieldValue: textFieldValue,
                      crossAxisCount: 1,
                      selectedAtIndex: widget.selectedAtIndex,
                      cryptoCurrencyList: textFieldValue.isEmpty
                          ? widget.items
                          : subCryptoCurrencyList,
                      itemsCount: itemsCount,
                      onItemSelected: widget.onItemSelected,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  width: 42.0,
                  alignment: Alignment.topCenter,
                  child: FittedBox(
                    child: FloatingActionButton(
                      elevation: 0,
                      backgroundColor: Colors.white,
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Icon(
                        Icons.close_outlined,
                        color: Palette.darkBlueCraiola,
                        size: 30.0,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
