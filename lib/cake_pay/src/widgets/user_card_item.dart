import 'package:cake_wallet/generated/i18n.dart';
import 'package:flutter/material.dart';
import 'image_placeholder.dart';

class UserCardItem extends StatelessWidget {
  UserCardItem(
      {required this.title, required this.subTitle, this.onTap, this.logoUrl, this.isNew = false});

  final VoidCallback? onTap;
  final String title;
  final String subTitle;
  final String? logoUrl;

  /// Shows a badge for cards whose details were never opened.
  final bool isNew;

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
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            logoUrl!,
                            fit: BoxFit.cover,
                            loadingBuilder: (BuildContext context, Widget child,
                                ImageChunkEvent? loadingProgress) {
                              if (loadingProgress == null) {
                                return child;
                              }

                              return Center(child: CircularProgressIndicator());
                            },
                            errorBuilder: (context, error, stackTrace) =>
                                CakePayCardImagePlaceholder(),
                          ),
                          if (isNew) const Positioned(top: 6, right: 6, child: _NewBadge()),
                        ],
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

class _NewBadge extends StatelessWidget {
  const _NewBadge();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        S.of(context).new_tag.toUpperCase(),
        style: TextStyle(
          color: colors.onPrimary,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
