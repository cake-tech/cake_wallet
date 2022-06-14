import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/src/widgets/discount_badge.dart';
import 'package:flutter/material.dart';

class CardItem extends StatelessWidget {

  CardItem({
    @required this.onTap,
    @required this.title,
    @required this.subTitle,
    this.logoUrl,
    this.hasDiscount = false,
  });

  final VoidCallback onTap;
  final String title;
  final String subTitle;
  final String logoUrl;
  final bool hasDiscount;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.20),
              ),
            ),
            child: Row(
              children: [
                if (logoUrl != null) ...[
                  ClipOval(
                    child: Image.network(
                      logoUrl,
                      width: 42.0,
                      height: 42.0,
                      loadingBuilder: (BuildContext _, Widget child, ImageChunkEvent loadingProgress) {
                        if (loadingProgress == null) {
                          return child;
                        } else {
                          return _PlaceholderContainer(text: 'Logo');
                        }
                      },
                      errorBuilder: (_, __, ___) => _PlaceholderContainer(text: '!'),
                    ),
                  ),
                  SizedBox(width: 5),
                ],
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color:  Palette.stateGray,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      subTitle,
                      style: TextStyle(
                          color:  Palette.niagara ,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Lato'),
                    )
                  ],
                ),
              ],
            ),
          ),
          if (hasDiscount)
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: DiscountBadge(),
              ),
            ),
        ],
      ),
    );
  }
}

class _PlaceholderContainer extends StatelessWidget {

  const _PlaceholderContainer({@required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      width: 42,
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: Colors.black,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(100),
      ),
    );
  }
}
