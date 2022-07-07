import 'package:flutter/material.dart';

class ReceiptRow extends StatelessWidget {
  const ReceiptRow({Key key, @required this.title, @required this.value}) : super(key: key);

  final String title;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).accentTextTheme.subhead.color,
            ),
          ),
          value,
        ],
      ),
    );
  }
}
