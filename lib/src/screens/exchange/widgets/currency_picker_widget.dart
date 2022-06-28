import 'package:flutter/material.dart';
import 'package:cw_core/crypto_currency.dart';
import 'picker_item.dart';
import 'currency_picker_item_widget.dart';

class CurrencyPickerWidget extends StatelessWidget {
  const CurrencyPickerWidget({
    @required this.crossAxisCount,
    @required this.selectedAtIndex,
    @required this.itemsCount,
    @required this.pickerItemsList,
    @required this.pickListItem,
  });

  final int crossAxisCount;
  final int selectedAtIndex;
  final int itemsCount;
  final Function pickListItem;
  final List<PickerItem<CryptoCurrency>> pickerItemsList;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).accentTextTheme.headline6.backgroundColor,
            borderRadius: BorderRadius.circular(14.0),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14.0),
            child: Scrollbar(
              child: GridView.builder(
                  padding: EdgeInsets.zero,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 2,
                    childAspectRatio: 3,
                  ),
                  itemCount: pickerItemsList.length,
                  itemBuilder: (BuildContext ctx, index) {
                    return PickerItemWidget(
                      onTap: () {
                        pickListItem(index);
                      },
                      title: pickerItemsList[index].title,
                      iconPath: pickerItemsList[index].iconPath,
                      tag: pickerItemsList[index].tag,
                    );
                  }),
            ),
          ),
        );
      },
    );
  }
}
