import 'package:flutter/material.dart';

class TopPanel extends StatelessWidget {
  TopPanel({@required this.color, @required this.widget});

  final Color color;
  final Widget widget;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24)
        ),
        color: color
      ),
      child: widget,
    );
  }
}