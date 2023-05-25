import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ListRow extends StatelessWidget {
  ListRow(
      {required this.title,
      required this.value,
      this.titleFontSize = 14,
      this.valueFontSize = 16,
      this.image});

  final String title;
  final String value;
  final double titleFontSize;
  final double valueFontSize;
  final Image? image;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.background,
      child: Padding(
        padding:
        const EdgeInsets.only(left: 24, top: 16, bottom: 16, right: 24),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title,
                  style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context)
                          .primaryTextTheme!
                          .labelSmall!
                          .color!),
                  textAlign: TextAlign.left),
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Text(value,
                          style: TextStyle(
                              fontSize: valueFontSize,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context)
                                  .primaryTextTheme!
                                  .titleLarge!
                                  .color!)),
                    ),
                    image != null
                    ? Padding(
                      padding: EdgeInsets.only(left: 24),
                      child: image,
                    )
                    : Offstage()
                  ],
                ),
              )
            ]),
      ),
    );
  }
}
