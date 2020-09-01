import 'package:flutter/material.dart';

class ActionButton extends StatelessWidget{
  ActionButton({
    @required this.image,
    @required this.title,
    @required this.route,
    this.alignment = Alignment.center
  });

  final Image image;
  final String title;
  final String route;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 93,
      alignment: alignment,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          GestureDetector(
            onTap: () {
              if (route.isNotEmpty) {
                Navigator.of(context, rootNavigator: true).pushNamed(route);
              }
            },
            child: Container(
              height: 60,
              width: 60,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(context).buttonColor,
                shape: BoxShape.circle),
              child: image,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white
            ),
          )
        ],
      ),
    );
  }
}