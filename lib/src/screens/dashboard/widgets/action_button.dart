import 'package:flutter/material.dart';
import 'package:cake_wallet/themes/extensions/dashboard_page_theme.dart';

class ActionButton extends StatelessWidget {
  ActionButton(
      {required this.image,
        required this.title,
        this.route,
        this.onClick,
        this.alignment = Alignment.center,
        this.textColor});

  final Image image;
  final String title;
  final String? route;
  final Alignment alignment;
  final VoidCallback? onClick;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (route?.isNotEmpty ?? false) {
          Navigator.of(context, rootNavigator: true).pushNamed(route!);
        } else {
          onClick?.call();
        }
      },
      child: Container(
        color: Colors.transparent,
        padding: EdgeInsets.only(top: 14, bottom: 16, left: 10, right: 10),
        alignment: alignment,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
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
                  fontSize: 10,
                  color: textColor ??
                      Theme.of(context).extension<DashboardPageTheme>()!.cardTextColor),
            )
          ],
        ),
      ),
    );
  }
}
