import 'package:cake_wallet/view_model/settings/choices_list_item.dart';
import 'package:flutter/material.dart';

class SettingsChoicesCell extends StatefulWidget {
  const SettingsChoicesCell(this.choicesListItem, {Key key}) : super(key: key);

  final ChoicesListItem choicesListItem;

  @override
  _SettingsChoicesCellState createState() => _SettingsChoicesCellState();
}

class _SettingsChoicesCellState extends State<SettingsChoicesCell> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).backgroundColor,
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                widget.choicesListItem.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: Theme.of(context).primaryTextTheme.title.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: Theme.of(context).accentTextTheme.display2.color,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: widget.choicesListItem.items.map((dynamic e) {
                    final isSelected = widget.choicesListItem.selectedItem() == e;
                    return GestureDetector(
                      onTap: () {
                        widget.choicesListItem.onItemSelected?.call(e);
                        setState(() {});
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: isSelected ? Theme.of(context).accentTextTheme.body2.color : null,
                        ),
                        child: Text(
                          widget.choicesListItem.displayItem?.call(e) ?? e.toString(),
                          style: TextStyle(
                            color: isSelected ? Colors.white : Theme.of(context).primaryTextTheme.caption.color,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
