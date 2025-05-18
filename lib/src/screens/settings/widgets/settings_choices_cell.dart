import 'package:cake_wallet/view_model/settings/choices_list_item.dart';
import 'package:flutter/material.dart';

class SettingsChoicesCell extends StatelessWidget {
  const SettingsChoicesCell(this.choicesListItem, {Key? key}) : super(key: key);

  final ChoicesListItem<dynamic> choicesListItem;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 16),
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
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          Center(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
                                  : Theme.of(context).colorScheme.onSurfaceVariant,
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
