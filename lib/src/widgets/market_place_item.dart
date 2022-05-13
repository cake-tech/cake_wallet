import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MarketPlaceItem extends StatelessWidget {
  final VoidCallback onTap;
  final String title;
  final String subTitle;
  final String logoUrl;
  final EdgeInsets padding;
  final bool hasDiscount;

  MarketPlaceItem({
    @required this.onTap,
    @required this.title,
    @required this.subTitle,
    this.logoUrl,
    this.padding,
    this.hasDiscount = false,
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
              color: Colors.white.withOpacity(0.20),
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
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      subTitle,
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
          if (hasDiscount) ...[
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Image.asset('assets/images/badge_discount.png'),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 22.0, right: 2),
                child: Text(
                  'Save 20%',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Lato',
                  ),
                ),
              ),
            )
          ],
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
