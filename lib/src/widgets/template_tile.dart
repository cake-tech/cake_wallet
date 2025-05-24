import 'package:cake_wallet/themes/utils/custom_theme_colors.dart';
import 'package:flutter/material.dart';

class TemplateTile extends StatefulWidget {
  TemplateTile({
    Key? key,
    required this.to,
    required this.amount,
    required this.from,
    required this.onTap,
    required this.onRemove,
    this.hasMultipleRecipients,
  }) : super(key: key);

  final String to;
  final String amount;
  final String from;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final bool? hasMultipleRecipients;

  @override
  TemplateTileState createState() => TemplateTileState(to, amount, from, onTap, onRemove);
}

class TemplateTileState extends State<TemplateTile> {
  TemplateTileState(this.to, this.amount, this.from, this.onTap, this.onRemove);

  final String to;
  final String amount;
  final String from;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  bool isRemovable = false;

  @override
  Widget build(BuildContext context) {
    final toIcon = Image.asset(
      'assets/images/to_icon.png',
      color: Theme.of(context).colorScheme.onSurface,
    );

    final content = Row(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: widget.hasMultipleRecipients ?? false
          ? [
              Text(
                to,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
            ]
          : [
              Text(
                amount,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 5),
                child: Text(
                  from,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 5),
                child: toIcon,
              ),
              Padding(
                padding: EdgeInsets.only(left: 5),
                child: Text(
                  to,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
              ),
            ],
    );

    final tile = Container(
        padding: EdgeInsets.only(right: 10),
        child: ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(12)),
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
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: content,
            ),
          ),
        ));

    final removableTile = Container(
      padding: EdgeInsets.only(right: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.all(Radius.circular(12)),
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
                color: CustomThemeColors.syncYellow,
                child: content,
              ),
            ),
            GestureDetector(
              onTap: onRemove,
              child: Container(
                height: 40,
                width: 44,
                color: Theme.of(context).colorScheme.errorContainer,
                child: Center(
                  child: Image.asset(
                    'assets/images/trash.png',
                    height: 16,
                    width: 16,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );

    return isRemovable ? removableTile : tile;
  }
}
