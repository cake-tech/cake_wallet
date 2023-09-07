import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/palette.dart';

class FAQItem extends StatefulWidget {
  FAQItem(this.title, this.text);

  final String title;
  final String text;

  @override
  State<StatefulWidget> createState() => FAQItemState();
}

class FAQItemState extends State<FAQItem> {
  FAQItemState()
    : isActive = false;

  bool isActive;

  @override
  void initState() {
    isActive = false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final addIcon = Icon(Icons.add,
        color: Theme.of(context).extension<CakeTextTheme>()!.titleColor);
    final removeIcon = Icon(Icons.remove, color: Palette.blueCraiola);
    final icon = isActive ? removeIcon : addIcon;
    final color = isActive
        ? Palette.blueCraiola
        : Theme.of(context).extension<CakeTextTheme>()!.titleColor;

    return ListTileTheme(
      contentPadding: EdgeInsets.fromLTRB(0, 6, 24, 6),
      child: ExpansionTile(
        title: Text(widget.title,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w500, color: color)),
        trailing: icon,
        onExpansionChanged: (value) => setState(() => isActive = value),
        children: <Widget>[
          Row(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
            Expanded(
                child: Container(
              padding: EdgeInsets.only(
                right: 24.0,
              ),
              child: Text(
                widget.text,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color:
                        Theme.of(context).extension<CakeTextTheme>()!.titleColor),
              ),
            ))
          ])
        ],
      ),
    );
  }
}
