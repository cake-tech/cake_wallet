import 'package:flutter/material.dart';
import 'package:cw_core/crypto_currency.dart';
import 'picker_Item.dart';
import 'currency_picker_Item_widget.dart';

class CurrencyPickerWidget extends StatefulWidget {
  CurrencyPickerWidget(
      {@required this.crossAxisCount,
      @required this.cryptoCurrencyList,
      @required this.selectedAtIndex,
      @required this.itemsCount,
      @required this.onItemSelected,
      this.textFieldValue});

  final int crossAxisCount;
  final List<CryptoCurrency> cryptoCurrencyList;
  int selectedAtIndex;
  final int itemsCount;
  final String textFieldValue;
  final Function onItemSelected;

  @override
  _CurrencyPickerWidgetState createState() => _CurrencyPickerWidgetState();
}

class _CurrencyPickerWidgetState extends State<CurrencyPickerWidget> {
  _CurrencyPickerWidgetState();

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
      decoration: BoxDecoration(
        color: Theme.of(context).accentTextTheme.headline6.backgroundColor,
        borderRadius: BorderRadius.circular(14.0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14.0),
        child: Scrollbar(
          showTrackOnHover: true,
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
                  title: PickerItem(
                          currencyIndex: widget.cryptoCurrencyList[index].raw)
                      .pickerTitle,
                  iconPath: PickerItem(
                          currencyIndex: widget.cryptoCurrencyList[index].raw)
                      .leftIcon,
                  isSelected: index == widget.selectedAtIndex,
                  tag: PickerItem(
                          currencyIndex: widget.cryptoCurrencyList[index].raw)
                      .tagName,
                );
              }),
        ),
      ),
    );
  }
}
