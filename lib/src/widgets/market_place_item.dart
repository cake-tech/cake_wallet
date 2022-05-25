import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/src/widgets/discount_badge.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MarketPlaceItem extends StatelessWidget {
  final VoidCallback onTap;
  final String title;
  final String subTitle;
  final String logoUrl;
  final EdgeInsets padding;
  final bool hasDiscount;
  final bool isWhiteBackground;

  MarketPlaceItem({
    @required this.onTap,
    @required this.title,
    @required this.subTitle,
    this.logoUrl,
    this.padding,
    this.hasDiscount = false,
    this.isWhiteBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            padding: padding ?? EdgeInsets.all(20),
            width: double.infinity,
            decoration: BoxDecoration(
              color: isWhiteBackground ? Colors.black.withOpacity(0.1) : Colors.white.withOpacity(0.20),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.20),
              ),
            ),
            child: Row(
              children: [
                if (logoUrl != null) ...[
                  ClipOval(
                    child: CachedNetworkImage(
                      width: 42.0,
                      height: 42.0,
                      imageUrl: logoUrl,
                      placeholder: (context, url) => _PlaceholderContainer(text: 'Logo'),
                      errorWidget: (context, url, error) => _PlaceholderContainer(text: '!'),
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
                        color: isWhiteBackground ? Palette.stateGray : Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      subTitle,
                      style: TextStyle(
                          color: isWhiteBackground ? Palette.niagara : Colors.white,
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
  final String text;

  const _PlaceholderContainer({@required this.text});

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
