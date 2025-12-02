import 'package:flutter/material.dart';

class DropDownItemWidget extends StatelessWidget {
  const DropDownItemWidget({super.key, required this.title, required this.image});
  final double tileHeight = 60;
  final Image image;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: tileHeight,
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          image,
          SizedBox(width: 10),
          Flexible(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          )
        ],
      ),
    );
  }
}
