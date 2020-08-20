import 'package:flutter/material.dart';

class TopPanel extends StatefulWidget {
  TopPanel({
    @required this.widget,
    this.edgeInsets = const EdgeInsets.all(24),
    this.color,
    this.gradient
  });

  final Color color;
  final Widget widget;
  final EdgeInsets edgeInsets;
  final Gradient gradient;

  @override
  TopPanelState createState() => TopPanelState(widget, edgeInsets, color, gradient);
}

class TopPanelState extends State<TopPanel> {
  TopPanelState(this._widget, this._edgeInsets, this._color, this._gradient);

  final Color _color;
  final Widget _widget;
  final EdgeInsets _edgeInsets;
  final Gradient _gradient;

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
        color: _color,
        gradient: _gradient
      ),
      child: _widget,
    );
  }
}