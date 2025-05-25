import 'package:flutter/material.dart';
import 'image_placeholder.dart';

class UserCardItem extends StatelessWidget {
  UserCardItem({
    required this.title,
    required this.subTitle,
    required this.backgroundColor,
    required this.titleColor,
    required this.subtitleColor,
    this.hideBorder = true,
    this.onTap,
    this.logoUrl
  });

  final VoidCallback? onTap;
  final String title;
  final String subTitle;
  final String? logoUrl;
  final bool hideBorder;
  final Color backgroundColor;
  final Color titleColor;
  final Color subtitleColor;

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
            borderRadius: BorderRadius.circular(15),
            border: hideBorder
                ? Border.all(color: Colors.transparent)
                : Border.all(color: Colors.white.withOpacity(0.20)),
          ),
          child: Column(
            children: [
              if (logoUrl != null)
                Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: AspectRatio(
                    aspectRatio: 1.65,
                    child: ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(13)),
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
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: titleColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      subTitle,
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}