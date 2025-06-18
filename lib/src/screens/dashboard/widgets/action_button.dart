import 'package:flutter/material.dart';

class ActionButton extends StatelessWidget {
  ActionButton({
    required this.image,
    required this.title,
    this.route,
    this.onClick,
    this.alignment = Alignment.center,
    this.textColor,
    super.key,
  });

  final Image image;
  final String title;
  final String? route;
  final Alignment alignment;
  final VoidCallback? onClick;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        if (route?.isNotEmpty ?? false) {
          Navigator.of(context, rootNavigator: true).pushNamed(route!);
        } else {
          onClick?.call();
        }
      },
      child: Container(
        color: Colors.transparent,
        padding: EdgeInsets.only(top: 5, bottom: 4, left: 0, right: 0),
        alignment: alignment,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          //mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  shape: BoxShape.circle),
              child: image,
            ),
            SizedBox(height: 4),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.visible,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: textColor ?? Theme.of(context).colorScheme.onSurface),
              textAlign: TextAlign.center,
            )
          ],
        ),
      ),
    );
  }
}
