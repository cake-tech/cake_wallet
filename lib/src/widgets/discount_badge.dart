import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';


class DiscountBadge extends StatelessWidget {
  const DiscountBadge({
    Key key,
    @required this.percentage,
  }) : super(key: key);

  final double percentage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text( S.of(context).discount(percentage.toString()),
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          fontFamily: 'Lato',
          ),
        ),
      decoration: BoxDecoration(
        image: DecorationImage(
          fit: BoxFit.fill,
          image:  AssetImage('assets/images/badge_discount.png'),
          ),
        ), 
      );
    }
}
