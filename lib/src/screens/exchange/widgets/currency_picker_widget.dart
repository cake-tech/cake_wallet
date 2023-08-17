import 'package:cake_wallet/themes/extensions/picker_theme.dart';
import 'package:cw_core/currency.dart';
import 'package:flutter/material.dart';
import 'currency_picker_item_widget.dart';

class CurrencyPickerWidget extends StatelessWidget {
  CurrencyPickerWidget({
    required this.crossAxisCount,
    required this.selectedAtIndex,
    required this.pickerItemsList,
    required this.pickListItem,
  });

  final int crossAxisCount;
  final int selectedAtIndex;
  final Function pickListItem;
  final List<Currency> pickerItemsList;

  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).extension<PickerTheme>()!.dividerColor,
      child: Scrollbar(
        controller: _scrollController,
        child: GridView.builder(
            controller: _scrollController,
            padding: EdgeInsets.zero,
            shrinkWrap: true,
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
                title: pickerItemsList[index].name,
                iconPath: pickerItemsList[index].iconPath, 
                tag: pickerItemsList[index].tag,
              );
            }),
      ),
    );
  }
}
