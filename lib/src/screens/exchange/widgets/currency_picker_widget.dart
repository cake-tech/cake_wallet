import 'package:cake_wallet/view_model/settings/picker_list_item.dart';
import 'package:flutter/material.dart';
import 'package:cw_core/crypto_currency.dart';
import 'picker_item.dart';
import 'currency_picker_item_widget.dart';

class CurrencyPickerWidget extends StatefulWidget {
  CurrencyPickerWidget(
      {@required this.crossAxisCount,
      @required this.cryptoCurrencyList,
      @required this.selectedAtIndex,
      @required this.itemsCount,
      @required this.onItemSelected,
      @required this.pickerItemsList,
      this.textFieldValue});

  final int crossAxisCount;
  final List<CryptoCurrency> cryptoCurrencyList;
  int selectedAtIndex;
  final int itemsCount;
  final String textFieldValue;
  final Function onItemSelected;
  final List<PickerItem<CryptoCurrency>> pickerItemsList;

  @override
  _CurrencyPickerWidgetState createState() => _CurrencyPickerWidgetState();
}

class _CurrencyPickerWidgetState extends State<CurrencyPickerWidget> {
  _CurrencyPickerWidgetState();

  void pickListItem(int index) {
    setState(() {
      widget.selectedAtIndex = index;
    });
    widget.onItemSelected(widget.pickerItemsList[index].original);
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
                  title: widget.pickerItemsList[index].title,
                  iconPath: widget.pickerItemsList[index].iconPath,
                  isSelected: index == widget.selectedAtIndex,
                  tag: widget.pickerItemsList[index].tag,
                );
              }),
        ),
      ),
    );
  }
}
