import 'package:flutter/material.dart';

class DiscountBadge extends StatelessWidget {
  const DiscountBadge({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.centerRight,
      children: [
        Image.asset('assets/images/badge_discount.png'),
        Padding(
          padding: const EdgeInsets.only(right: 10.0),
          child: Text(
            'Save 20%',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              fontFamily: 'Lato',
            ),
          ),
        )
      ],
    );
  }
}
