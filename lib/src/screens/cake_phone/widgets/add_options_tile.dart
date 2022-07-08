import 'package:flutter/material.dart';

class AddOptionsTile extends StatelessWidget {
  const AddOptionsTile({Key key, @required this.leading, this.onTap}) : super(key: key);

  final Widget leading;
  final Function() onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(15)),
          color: Theme.of(context).primaryTextTheme.display3.decorationColor,
        ),
        child: Row(
          children: [
            Expanded(
              child: leading,
            ),
            Container(
              width: 2,
              height: 48,
              color: Theme.of(context).primaryTextTheme.title.color,
            ),
            const SizedBox(width: 16),
            Icon(
              Icons.add_circle,
              color: Theme.of(context).primaryTextTheme.title.color,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
