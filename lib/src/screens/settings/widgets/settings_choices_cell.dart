import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/view_model/settings/choices_list_item.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/themes/extensions/address_theme.dart';

class SettingsChoicesCell extends StatelessWidget {
  const SettingsChoicesCell(this.choicesListItem, {Key? key}) : super(key: key);

  final ChoicesListItem<dynamic> choicesListItem;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.background,
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (choicesListItem.title.isNotEmpty) ...[
            Row(
              children: [
                Text(
                  choicesListItem.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
          Center(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: Theme.of(context).extension<AddressTheme>()!.actionButtonColor,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: choicesListItem.items.map((dynamic e) {
                  final isSelected = choicesListItem.selectedItem == e;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        choicesListItem.onItemSelected.call(e);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: isSelected ? Theme.of(context).primaryColor : null,
                        ),
                        child: Center(
                          child: Text(
                            choicesListItem.displayItem.call(e),
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Theme.of(context).extension<CakeTextTheme>()!.secondaryTextColor,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
