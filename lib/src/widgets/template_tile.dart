import 'package:cake_wallet/entities/template.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/palette.dart';

class TemplateTile extends StatefulWidget {
  TemplateTile(
      {Key? key,
      required this.to,
      required this.amount,
      required this.from,
      required this.onTap,
      required this.onRemove,
      this.recipients})
      : super(key: key);

  final String to;
  final String amount;
  final String from;
  final List<Template>? recipients;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  TemplateTileState createState() =>
      TemplateTileState(to, amount, from, onTap, onRemove, recipients);
}

class TemplateTileState extends State<TemplateTile> {
  TemplateTileState(this.to, this.amount, this.from, this.onTap, this.onRemove,
      this.recipients);

  final String to;
  final String amount;
  final String from;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  List<Template>? recipients;
  final trash = Image.asset('assets/images/trash.png',
      height: 16, width: 16, color: Colors.white);

  bool isRemovable = false;

  @override
  Widget build(BuildContext context) {
    final color = isRemovable
        ? Colors.white
        : Theme.of(context).primaryTextTheme.titleLarge!.color!;

    final content = Row(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ...buildTextContents(amount, from, to, color),
          if (recipients != null && recipients!.isNotEmpty)
            ...recipients!
                .sublist(1)
                .map((template) => [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 5),
                        child: Icon(Icons.add, size: 16, color: color),
                      ),
                      ...buildTextContents(
                        template.isCurrencySelected
                            ? template.amount
                            : template.amountFiat,
                        template.isCurrencySelected
                            ? template.cryptoCurrency
                            : template.fiatCurrency,
                        template.name,
                        color,
                      ),
                    ])
                .expand((i) => i)
                .toList(),
        ]);

    final tile = Container(
        padding: EdgeInsets.only(right: 10),
        child: ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          child: GestureDetector(
            onTap: onTap,
            onLongPress: () {
              setState(() {
                isRemovable = true;
              });
            },
            child: Container(
              height: 40,
              padding: EdgeInsets.only(left: 24, right: 24),
              color: Theme.of(context).primaryTextTheme!.displayMedium!.decorationColor!,
              child: content,
            ),
          ),
        )
    );

    final removableTile = Container(
        padding: EdgeInsets.only(right: 10),
        child: ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(20)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                GestureDetector(
                  onTap: () {
                    setState(() {
                      isRemovable = false;
                    });
                  },
                  child: Container(
                    height: 40,
                    padding: EdgeInsets.only(left: 24, right: 10),
                    color: Colors.orange,
                    child: content,
                  ),
                ),
                GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    height: 40,
                    width: 44,
                    color: Palette.darkRed,
                    child: Center(
                      child: trash,
                    ),
                  ),
                )
              ],
            )
        )
    );

    return isRemovable ? removableTile : tile;
  }
}

List<Widget> buildTextContents(
    String amount, String from, String to, Color color) {
  final toIcon = Image.asset('assets/images/to_icon.png', color: color);

  return <Widget>[
    Text(amount,
        style:
            TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color)),
    Padding(
      padding: EdgeInsets.only(left: 5),
      child: Text(from,
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600, color: color)),
    ),
    Padding(padding: EdgeInsets.only(left: 5), child: toIcon),
    Padding(
        padding: EdgeInsets.only(left: 5),
        child: Text(to,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: color)))
  ];
}
