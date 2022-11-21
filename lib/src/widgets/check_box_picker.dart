import 'package:cake_wallet/palette.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/src/widgets/alert_background.dart';
import 'package:cake_wallet/src/widgets/alert_close_button.dart';

class CheckBoxPicker extends StatefulWidget {
  CheckBoxPicker({
    required this.items,
    required this.onChanged,
    required this.title,
    this.displayItem,
    this.isSeparated = true,
  });

  final List<CheckBoxItem> items;
  final String title;
  final Widget Function(CheckBoxItem)? displayItem;
  final bool isSeparated;
  final Function(int, bool) onChanged;

  @override
  CheckBoxPickerState createState() => CheckBoxPickerState(items);
}

class CheckBoxPickerState extends State<CheckBoxPicker> {
  CheckBoxPickerState(this.items);

  final List<CheckBoxItem> items;

  ScrollController controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    return AlertBackground(
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (widget.title?.isNotEmpty ?? false)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'Lato',
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none,
                      color: Colors.white,
                    ),
                  ),
                ),
              Padding(
                padding: EdgeInsets.only(left: 24, right: 24, top: 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(30)),
                  child: Container(
                    color: Theme.of(context).accentTextTheme!.headline6!.color!,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.65,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Stack(
                              alignment: Alignment.center,
                              children: <Widget>[
                                (items?.length ?? 0) > 3
                                    ? Scrollbar(
                                        controller: controller,
                                        child: itemsList(),
                                      )
                                    : itemsList(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
          AlertCloseButton(),
        ],
      ),
    );
  }

  Widget itemsList() {
    return Container(
      color: Theme.of(context).accentTextTheme!.headline6!.backgroundColor!,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        controller: controller,
        shrinkWrap: true,
        separatorBuilder: (context, index) => widget.isSeparated
            ? Divider(
                color: Theme.of(context).accentTextTheme!.headline6!.backgroundColor!,
                height: 1,
              )
            : const SizedBox(),
        itemCount: items == null || items.isEmpty ? 0 : items.length,
        itemBuilder: (context, index) => buildItem(index),
      ),
    );
  }

  Widget buildItem(int index) {
    final item = items[index];

    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
      },
      child: Container(
        height: 55,
        color: Theme.of(context).accentTextTheme!.headline6!.color!,
        padding: EdgeInsets.only(left: 24, right: 24),
        child: CheckboxListTile(
          value: item.value,
          activeColor: item.value
              ? Palette.blueCraiola
              : Theme.of(context).accentTextTheme!.subtitle1!.decorationColor!,
          checkColor: Colors.white,
          title: widget.displayItem?.call(item) ??
              Text(
                item.title,
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Lato',
                  fontWeight: FontWeight.w600,
                  color: item.isDisabled
                      ? Colors.grey.withOpacity(0.5)
                      : Theme.of(context).primaryTextTheme!.headline6!.color!,
                  decoration: TextDecoration.none,
                ),
              ),
          onChanged: (bool? value) {
            if (value == null) {
              return;
            }
            
            item.value = value;
            widget.onChanged(index, value);
            setState(() {});
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ),
    );
  }
}

class CheckBoxItem {
  CheckBoxItem(this.title, this.value, {this.isDisabled = false});

  final String title;
  final bool isDisabled;
  bool value;
}
