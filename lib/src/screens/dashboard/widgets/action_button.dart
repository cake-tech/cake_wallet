import 'package:flutter/material.dart';
import 'package:cake_wallet/themes/extensions/dashboard_page_theme.dart';

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
        padding: EdgeInsets.only(top: 5, bottom: 5, left: 0, right: 0),
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
              style: TextStyle(
                  fontSize: 9,
                  color: textColor ??
                      Theme.of(context).extension<DashboardPageTheme>()!.cardTextColor),
              textAlign: TextAlign.center,
            )
          ],
        ),
      ),
    );
  }
}
