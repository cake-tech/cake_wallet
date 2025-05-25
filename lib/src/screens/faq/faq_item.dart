import 'package:flutter/material.dart';

class FAQItem extends StatefulWidget {
  FAQItem(this.title, this.text);

  final String title;
  final String text;

  @override
  State<StatefulWidget> createState() => FAQItemState();
}

class FAQItemState extends State<FAQItem> {
  FAQItemState() : isActive = false;

  bool isActive;

  @override
  void initState() {
    isActive = false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final addIcon = Icon(Icons.add, color: Theme.of(context).colorScheme.onSurface);
    final removeIcon = Icon(Icons.remove, color: Theme.of(context).colorScheme.primary);
    final icon = isActive ? removeIcon : addIcon;
    final color =
        isActive ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface;

    return ListTileTheme(
      contentPadding: EdgeInsets.fromLTRB(0, 6, 24, 6),
      child: ExpansionTile(
        title: Text(
          widget.title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
                color: color,
              ),
        ),
        trailing: icon,
        onExpansionChanged: (value) => setState(() => isActive = value),
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Container(
                  padding: EdgeInsets.only(
                    right: 24.0,
                  ),
                  child: Text(
                    widget.text,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}
