import 'package:flutter/material.dart';

class MobileExchangeCardsSection extends StatelessWidget {
  final Widget firstExchangeCard;
  final Widget secondExchangeCard;

  const MobileExchangeCardsSection({
    Key? key,
    required this.firstExchangeCard,
    required this.secondExchangeCard,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: 32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryTextTheme.bodyText2!.color!,
            Theme.of(context).primaryTextTheme.bodyText2!.decorationColor!,
          ],
          stops: [0.35, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryTextTheme.subtitle2!.color!,
                  Theme.of(context).primaryTextTheme.subtitle2!.decorationColor!,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: EdgeInsets.fromLTRB(24, 100, 24, 32),
            child: firstExchangeCard,
          ),
          Padding(
            padding: EdgeInsets.only(top: 29, left: 24, right: 24),
            child: secondExchangeCard,
          )
        ],
      ),
    );
  }
}
