import 'package:flutter/material.dart';
import 'image_placeholder.dart';

class UserCardItem extends StatelessWidget {
  UserCardItem({
    required this.title,
    required this.subTitle,
    this.onTap,
    this.logoUrl
  });

  final VoidCallback? onTap;
  final String title;
  final String subTitle;
  final String? logoUrl;

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
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(15),
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
                      child: Text(title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                    SizedBox(width: 8),
                    Text(subTitle,
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .copyWith(fontSize: 16, fontWeight: FontWeight.w700)),
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