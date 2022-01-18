import 'dart:ui';
import 'package:cake_wallet/palette.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cake_wallet/src/widgets/alert_background.dart';
import 'package:cake_wallet/src/widgets/cake_scrollbar.dart';

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
  final int crossAxisCount = 2;
  final int maxNumberItemsInAlert = 12;
  int itemsCount;
  final double backgroundHeight = 280;
  final double thumbHeight = 72;
  ScrollController controller = ScrollController();
  double fromTop = 0;
  bool isSearchBarActive = false;
  String textFieldValue = '';
  List<String> subItems = [];
  List<int> subItemsIndexList = [];
  List<CryptoCurrency> subCryptoCurrencyList = [];
  TextStyle appBarTextStyle = TextStyle(
      fontSize: 20,
      fontFamily: 'Lato',
      backgroundColor: Colors.transparent,
      color: Colors.white);

  void pickListItem(int index) {
    setState(() {
      widget.selectedAtIndex = index;
    });
    Navigator.of(context).pop();
  }

  void searchByTextFieldValue(String subString, List<CryptoCurrency> list) {
    subItems = [];
    setState(() {
      if (subString.isNotEmpty) {
        list.forEach((dynamic element) {
          subItems.add(element.toString());
        });

        subItemsIndexList = [];
        subItems.forEach((element) {
          if (element.contains(textFieldValue.toUpperCase())) {
            subItemsIndexList.add(subItems.indexOf(element));
          }
        });

        for (var i = 0; i < subItemsIndexList.length; i++) {
          subCryptoCurrencyList.add(list[subItemsIndexList[i]]);
        }

        subItems = (subItems.where(
            (item) => item.contains(textFieldValue.toUpperCase()))).toList();

        itemsCount = subItems.length;
      } else {
        itemsCount = items.length;
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

    controller.addListener(() {
      fromTop = controller.hasClients
          ? (controller.offset /
              controller.position.maxScrollExtent *
              (backgroundHeight - thumbHeight))
          : 0;
      setState(() {});
    });

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
                            'Cancel',
                            style: appBarTextStyle,
                          ),
                          onTap: () {
                            setState(() {
                              isSearchBarActive = false;
                            });
                          }),
                    ),
                    Container(
                      width: 100.0,
                      child: CupertinoTextField(
                          autofocus: true,
                          placeholder: 'Search...',
                          placeholderStyle: appBarTextStyle,
                          decoration: BoxDecoration(color: Colors.transparent),
                          cursorColor: Colors.white,
                          cursorHeight: 23.0,
                          style: appBarTextStyle,
                          onChanged: (value) {
                            this.textFieldValue = value;
                            searchByTextFieldValue(
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
            Container(
              height: pickerHeight,
              width: width * 0.9,
              decoration: BoxDecoration(
                color:
                    Theme.of(context).accentTextTheme.headline6.backgroundColor,
                borderRadius: BorderRadius.circular(14.0),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14.0),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    GridView.count(
                      padding: EdgeInsets.all(0),
                      controller: controller,
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: (width * 0.9 / 2) / (height * 0.75 / 9),
                      crossAxisSpacing: 1,
                      mainAxisSpacing: 1,
                      children: List.generate(
                          itemsCount < 18
                              ? itemsCount + (18 - itemsCount)
                              : itemsCount,
                          (index) => index < itemsCount
                              ? GestureDetector(
                                  onTap: () {
                                    pickListItem(index);
                                    widget.onItemSelected(textFieldValue.isEmpty
                                        ? items[index]
                                        : subCryptoCurrencyList[index]);
                                  },
                                  child: Container(
                                    color: index == widget.selectedAtIndex
                                        ? Theme.of(context)
                                            .textTheme
                                            .bodyText1
                                            .color
                                        : Theme.of(context)
                                            .accentTextTheme
                                            .headline6
                                            .color,
                                    child: Center(
                                        child: Text(
                                      textFieldValue.isEmpty
                                          ? items[index].toString()
                                          : subItems[index],
                                      style: TextStyle(
                                          color: index == widget.selectedAtIndex
                                              ? Palette.blueCraiola
                                              : Theme.of(context)
                                                  .primaryTextTheme
                                                  .title
                                                  .color,
                                          fontSize: 18.0),
                                    )),
                                  ),
                                )
                              : Container(
                                  color: Colors.white,
                                )),
                    ),
                    if (itemsCount > 18)
                      CakeScrollbar(
                          backgroundHeight: backgroundHeight,
                          thumbHeight: thumbHeight,
                          fromTop: fromTop)
                  ],
                ),
              ),
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
