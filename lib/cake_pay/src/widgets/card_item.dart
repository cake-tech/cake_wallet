import 'package:flutter/material.dart';

import 'image_placeholder.dart';

class CardItem extends StatelessWidget {
  CardItem({
    required this.title,
    required this.subTitle,
    required this.backgroundColor,
    required this.titleColor,
    required this.subtitleColor,
    this.hideBorder = true,
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
    return Theme(
      data: ThemeData(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(10),
            border: hideBorder
                ? Border.all(color: Colors.transparent)
                : Border.all(color: Colors.white.withOpacity(0.20)),
          ),
          child: Row(
            children: [
              if (logoUrl != null)
                AspectRatio(
                  aspectRatio: 1.8,
                  child: ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    child: Image.network(
                      logoUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder:
                          (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) => CakePayCardImagePlaceholder(),
                    ),
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: titleColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        subTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: titleColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
