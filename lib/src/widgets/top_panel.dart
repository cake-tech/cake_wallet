import 'package:flutter/material.dart';

class TopPanel extends StatefulWidget {
  TopPanel({
    @required this.color,
    @required this.widget,
    this.edgeInsets = const EdgeInsets.all(24)
  });

  final Color color;
  final Widget widget;
  final EdgeInsets edgeInsets;

  @override
  TopPanelState createState() => TopPanelState(color, widget, edgeInsets);
}

class TopPanelState extends State<TopPanel> {
  TopPanelState(this._color, this._widget, this._edgeInsets);

  final Color _color;
  final Widget _widget;
  final EdgeInsets _edgeInsets;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: _edgeInsets,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24)
        ),
        color: _color
      ),
      child: _widget,
    );
  }
}