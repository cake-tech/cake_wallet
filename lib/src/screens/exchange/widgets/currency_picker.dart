import 'dart:ui';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/src/screens/exchange/widgets/pickerItem.dart';
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
  CurrencyPickerState(this.items) : itemsCount = items.length;

  List<CryptoCurrency> items;
  int itemsCount;
  bool isSearchBarActive = false;
  String textFieldValue = '';
  List<CryptoCurrency> subCryptoCurrencyList = [];
  TextStyle appBarTextStyle = TextStyle(
      fontSize: 20,
      fontFamily: 'Lato',
      backgroundColor: Colors.transparent,
      color: Colors.white);

  void currencySearchBySubstring(String subString, List<CryptoCurrency> list) {
    subCryptoCurrencyList = [];
    setState(() {
      if (subString.isNotEmpty) {
        items.forEach((element) {
          if (element.title.contains(subString.toUpperCase()) ||
              PickerItem(currencyIndex: element.raw)
                  .currencyName
                  .contains(subString.toLowerCase())) {
            subCryptoCurrencyList.add(element);
          }
        });
        itemsCount = subCryptoCurrencyList.length;
      } else {
        itemsCount = list.length;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final double height = MediaQuery.of(context).size.height;
    final double width = MediaQuery.of(context).size.width;
    final double toolbarHeight = height * 0.1;
    final double pickerHeight = height * 0.7;
    final double bottomPickerPadding = height * 0.02;
    final double bottomBarHeight = height * 0.09;

    return AlertBackground(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          toolbarHeight: toolbarHeight,
          automaticallyImplyLeading: false,
          elevation: 0,
          title: isSearchBarActive
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: width * 0.05),
                      child: InkWell(
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
                    ),
                    Container(
                      width: 100.0,
                      child: CupertinoTextField(
                          autofocus: true,
                          placeholder: S.of(context).search + '...',
                          placeholderStyle: appBarTextStyle,
                          decoration: BoxDecoration(color: Colors.transparent),
                          cursorColor: Colors.white,
                          cursorHeight: 23.0,
                          style: appBarTextStyle,
                          onChanged: (value) {
                            this.textFieldValue = value;
                            currencySearchBySubstring(
                                textFieldValue, widget.items);
                          }),
                    ),
                  ],
                )
              : Text(
                  widget.title,
                  style: appBarTextStyle,
                ),
          centerTitle: !isSearchBarActive,
          actions: [
            Padding(
              padding: EdgeInsets.only(right: width * 0.05),
              child: IconButton(
                icon: Icon(Icons.search, color: Colors.white),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
                onPressed: () {
                  setState(() {
                    isSearchBarActive = true;
                  });
                },
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            CurrencyPickerWidget(
              textFieldValue: textFieldValue,
              crossAxisCount: 2,
              height: pickerHeight,
              width: width * 0.9,
              selectedAtIndex: widget.selectedAtIndex,
              cryptoCurrencyList:
                  textFieldValue.isEmpty ? widget.items : subCryptoCurrencyList,
              itemsCount: itemsCount,
              onItemSelected: widget.onItemSelected,
            ),
            SizedBox(
              height: bottomPickerPadding,
              width: width,
            ),
            Container(
              height: bottomBarHeight,
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
          ],
        ),
      ),
    );
  }
}
