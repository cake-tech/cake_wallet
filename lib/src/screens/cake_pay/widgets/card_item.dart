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
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: hideBorder
              ? Border.all(color: Colors.transparent)
              : Border.all(color: Colors.white.withOpacity(0.20)),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              if (logoUrl != null)
                Expanded(
                  flex: 2,
                  child: ClipRRect(
                    borderRadius: BorderRadius.horizontal(left: Radius.circular(20)),
                    child: Image.network(
                      logoUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder:
                          (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) =>
                          _PlaceholderContainer(text: '!'),
                    ),
                  ),
                ),
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: titleColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        subTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: subtitleColor,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Lato',
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

class _PlaceholderContainer extends StatelessWidget {
  const _PlaceholderContainer({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
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
      ),
    );
  }
}
