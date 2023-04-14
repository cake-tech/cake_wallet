import 'package:flutter/material.dart';

class DesktopExchangeCardsSection extends StatelessWidget {
  final Widget firstExchangeCard;
  final Widget secondExchangeCard;

  const DesktopExchangeCardsSection({
    Key? key,
    required this.firstExchangeCard,
    required this.secondExchangeCard,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(top: 55, left: 24, right: 24),
            child: firstExchangeCard,
          ),
          Padding(
            padding: EdgeInsets.only(top: 29, left: 24, right: 24),
            child: secondExchangeCard,
          ),
        ],
      ),
    );
  }
}
