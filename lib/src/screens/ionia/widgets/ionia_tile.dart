import 'package:cake_wallet/typography.dart';
import 'package:flutter/material.dart';

class IoniaTile extends StatelessWidget {
  const IoniaTile({
    Key key,
    @required this.title,
    @required this.subTitle,
    this.trailing,
    this.onTapTrailing,
  }) : super(key: key);

  final Widget trailing;
  final VoidCallback onTapTrailing;
  final String title;
  final String subTitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: textXSmall(
                color: Theme.of(context).primaryTextTheme.overline.color,
              ),
            ),
            SizedBox(height: 8),
            Text(
              subTitle,
              style: textMediumBold(
                color: Theme.of(context).primaryTextTheme.title.color,
              ),
            ),
          ],
        ),
        trailing != null
            ? InkWell(
                onTap: () => onTapTrailing,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    decoration: BoxDecoration(
                        color: Theme.of(context).accentTextTheme.display4.backgroundColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4)),
                    child: trailing,
                  ),
                ),
              )
            : Offstage(),
      ],
    );
  }
}
