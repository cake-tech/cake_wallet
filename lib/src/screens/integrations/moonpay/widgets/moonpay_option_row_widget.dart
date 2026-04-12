import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:flutter/material.dart';

class OptionCard extends StatelessWidget {
  const OptionCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: _buildChildrenWithDividers(context),
      ),
    );
  }

  List<Widget> _buildChildrenWithDividers(BuildContext context) {
    final result = <Widget>[];

    for (int i = 0; i < children.length; i++) {
      if (i > 0) {
        result.add(
          Padding(
            padding: const EdgeInsets.only(left: 50, right: 12),
            child: Divider(
              height: 1,
              thickness: 1,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(40),
            ),
          ),
        );
      }

      result.add(children[i]);
    }

    return result;
  }
}

class OptionRow extends StatelessWidget {
  const OptionRow({
    this.image,
    this.icon,
    required this.title,
    required this.subtitle,
    this.showChevron = false,
    this.onTap,
  });

  final String? image;
  final String? icon;
  final String title;
  final String subtitle;
  final bool showChevron;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      splashFactory: NoSplash.splashFactory,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          children: [
            image != null && image!.isNotEmpty
                ? CakeImageWidget(
                    imageUrl: image,
                    height: 24,
                    width: 24,
                    fit: BoxFit.contain,
                  )
                : icon != null
                    ? Container(
                        height: 24,
                        width: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.surfaceContainerHigh,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          icon!,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      )
                    : const SizedBox(),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            if (showChevron)
              Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}
