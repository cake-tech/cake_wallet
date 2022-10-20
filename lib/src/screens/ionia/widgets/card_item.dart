import 'package:cake_wallet/src/widgets/discount_badge.dart';
import 'package:flutter/material.dart';

class CardItem extends StatelessWidget {
  CardItem({
    required this.title,
    required this.subTitle,
    required this.backgroundColor,
    required this.titleColor,
    required this.subtitleColor,
    this.hideBorder = false,
    this.discount = 0.0,
    this.isAmount = false,
    this.discountBackground,
    this.onTap,
    this.logoUrl,
  });

  final VoidCallback? onTap;
  final String title;
  final String subTitle;
  final String? logoUrl;
  final double discount;
  final bool isAmount;
  final bool hideBorder;
  final Color backgroundColor;
  final Color titleColor;
  final Color subtitleColor;
  final AssetImage? discountBackground;

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
              color: backgroundColor,
              borderRadius: BorderRadius.circular(20),
              border: hideBorder ? Border.symmetric(horizontal: BorderSide.none, vertical: BorderSide.none) : Border.all(
                color: Colors.white.withOpacity(0.20),
              ),
            ),
            child: Row(
              children: [
                if (logoUrl != null) ...[
                  ClipOval(
                    child: Image.network(
                      logoUrl!,
                      width: 40.0,
                      height: 40.0,
                      fit: BoxFit.cover,
                      loadingBuilder: (BuildContext _, Widget child, ImageChunkEvent? loadingProgress) {
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
                  crossAxisAlignment: (subTitle?.isEmpty ?? false)
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 200,
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: titleColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (subTitle?.isNotEmpty ?? false)
                      Padding(
                        padding: EdgeInsets.only(top: 5),
                        child: Text(
                          subTitle,
                          style: TextStyle(
                            color: subtitleColor,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Lato')),
                    )
                  ],
                ),
              ],
            ),
          ),
          if (discount != 0.0)
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: DiscountBadge(
                  percentage: discount,
                  isAmount: isAmount,
                  discountBackground: discountBackground,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PlaceholderContainer extends StatelessWidget {
  const _PlaceholderContainer({required this.text});

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
