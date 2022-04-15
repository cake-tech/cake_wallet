import 'dart:ui';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/src/screens/exchange/widgets/currency_utils.dart';
import 'package:cake_wallet/src/screens/exchange/widgets/picker_item.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cake_wallet/src/widgets/alert_background.dart';
import 'currency_picker_widget.dart';

class CurrencyPicker extends StatefulWidget {
  CurrencyPicker(
      {@required this.selectedAtIndex,
      @required this.items,
      @required this.title,
      @required this.onItemSelected,
      this.isMoneroWallet = false,
      this.isConvertFrom = false});

  int selectedAtIndex;
  final List<CryptoCurrency> items;
  final String title;
  final Function(CryptoCurrency) onItemSelected;
  final bool isMoneroWallet;
  final bool isConvertFrom;

  @override
  CurrencyPickerState createState() => CurrencyPickerState(items);
}

class CurrencyPickerState extends State<CurrencyPicker> {
  CurrencyPickerState(this.items)
      : isSearchBarActive = false,
        textFieldValue = '',
        subPickerItemsList = [],
        appBarTextStyle = TextStyle(
            fontSize: 20,
            fontFamily: 'Lato',
            backgroundColor: Colors.transparent,
            color: Colors.white);

  @override
  void initState() {
    pickerItemsList = CryptoCurrency.all
        .map((CryptoCurrency cur) => PickerItem<CryptoCurrency>(cur,
            title: CurrencyUtils.titleForCurrency(cur),
            iconPath: CurrencyUtils.iconPathForCurrency(cur),
            tag: CurrencyUtils.tagForCurrency(cur),
            description: CurrencyUtils.descriptionForCurrency(cur)))
        .toList();
    cleanSubPickerItemsList();
    super.initState();
  }

  List<PickerItem<CryptoCurrency>> pickerItemsList;
  List<CryptoCurrency> items;
  bool isSearchBarActive;
  String textFieldValue;
  List<PickerItem<CryptoCurrency>> subPickerItemsList;
  TextStyle appBarTextStyle;

  void cleanSubPickerItemsList() {
    subPickerItemsList = pickerItemsList
        .where((element) => items.contains(element.original))
        .toList();
  }

  void currencySearchBySubstring(
      String subString, List<PickerItem<CryptoCurrency>> list) {
    setState(() {
      if (subString.isNotEmpty) {
        subPickerItemsList = subPickerItemsList
            .where((element) =>
                element.title.contains(subString.toUpperCase()) ||
                element.description.contains(subString.toLowerCase()))
            .toList();
      } else {
        cleanSubPickerItemsList();
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
                                          cleanSubPickerItemsList();
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
                                          cleanSubPickerItemsList();
                                          currencySearchBySubstring(
                                              textFieldValue,
                                              subPickerItemsList);
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
                      crossAxisCount: 2,
                      selectedAtIndex: widget.selectedAtIndex,
                      itemsCount: subPickerItemsList.length,
                      pickerItemsList: subPickerItemsList,
                      pickListItem: (int index) {
                        setState(() {
                          widget.selectedAtIndex = index;
                        });
                        widget
                            .onItemSelected(subPickerItemsList[index].original);
                        if (widget.isConvertFrom &&
                            !widget.isMoneroWallet &&
                            (subPickerItemsList[index].original ==
                                CryptoCurrency.xmr)) {
                        } else {
                          Navigator.of(context).pop();
                        }
                      },
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
