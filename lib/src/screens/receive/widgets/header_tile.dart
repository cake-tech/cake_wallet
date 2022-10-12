import 'package:flutter/material.dart';

class HeaderTile extends StatelessWidget {
  HeaderTile({
    required this.onTap,
    required this.title,
    required this.icon
  });

  final VoidCallback onTap;
  final String title;
  final Icon icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: 24
        ),
        color: Theme.of(context).textTheme!.headline3!.decorationColor!,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              title,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme!.headline3!.color!
              ),
            ),
            Container(
              height: 32,
              width: 32,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).textTheme!.headline4!.decorationColor!
              ),
              child: icon,
            )
          ],
        ),
      ),
    );
  }
}