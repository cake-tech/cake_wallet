import 'package:flutter/material.dart';

class PrefixCurrencyIcon extends StatelessWidget {
  PrefixCurrencyIcon({
    @required this.isSelected,
    @required this.title,
  });

  final bool isSelected;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.fromLTRB(0, 6.0, 8.0, 0),
        child: Column(children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              color: isSelected ? Colors.green : Colors.transparent,
            ),
            child: Text(title + ':',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                )),
          )
        ]));
  }
}
