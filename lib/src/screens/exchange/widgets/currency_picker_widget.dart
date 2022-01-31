import 'package:flutter/material.dart';
import 'package:cw_core/crypto_currency.dart';
import 'pickerItem.dart';
import 'currency_pickerItem_widget.dart';

class CurrencyPickerWidget extends StatefulWidget {
  CurrencyPickerWidget(
      {@required this.height,
      @required this.width,
      @required this.crossAxisCount,
      @required this.cryptoCurrencyList,
      @required this.selectedAtIndex,
      @required this.itemsCount,
      @required this.onItemSelected,
      this.textFieldValue});

  final double height;
  final double width;
  final int crossAxisCount;
  final List<CryptoCurrency> cryptoCurrencyList;
  int selectedAtIndex;
  final int itemsCount;
  final String textFieldValue;
  final Function onItemSelected;

  @override
  _CurrencyPickerWidgetState createState() =>
      _CurrencyPickerWidgetState(height);
}

class _CurrencyPickerWidgetState extends State<CurrencyPickerWidget> {
  _CurrencyPickerWidgetState(this.height);

  double height;

  void pickListItem(int index) {
    setState(() {
      widget.selectedAtIndex = index;
      widget.onItemSelected(widget.cryptoCurrencyList[index]);
    });
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      width: widget.width,
      decoration: BoxDecoration(
        color: Theme.of(context).accentTextTheme.headline6.backgroundColor,
        borderRadius: BorderRadius.circular(14.0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14.0),
        child: Scrollbar(
          isAlwaysShown: true,
          thickness: 6.0,
          radius: Radius.circular(3),
          child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 5 / 2,
                  crossAxisSpacing: 1,
                  mainAxisSpacing: 1),
              itemCount: widget.cryptoCurrencyList.length,
              itemBuilder: (BuildContext ctx, index) {
                return PickerItemWidget(
                  onTap: () {
                    pickListItem(index);
                  },
                  pickerItemTitle: PickerItem(
                          currencyIndex: widget.cryptoCurrencyList[index].raw)
                      .pickerTitle,
                  leftIconImage: PickerItem(
                          currencyIndex: widget.cryptoCurrencyList[index].raw)
                      .leftIcon,
                  isSelected: index == widget.selectedAtIndex,
                  tagName: PickerItem(
                          currencyIndex: widget.cryptoCurrencyList[index].raw)
                      .tagName,
                );
              }),
        ),
      ),
    );
  }
}
