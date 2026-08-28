import "package:flutter/material.dart";

class SeedPageHeader extends StatelessWidget {
  const SeedPageHeader({
    required this.image,
    required this.title,
    required this.description,
    this.imageSpacing = 24,
    this.titleSpacing = 12,
    super.key,
  });

  final Widget image;
  final String title;
  final Widget description;
  final double imageSpacing;
  final double titleSpacing;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(child: image),
          SizedBox(height: imageSpacing),
          Semantics(
            header: true,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(letterSpacing: -0.09),
            ),
          ),
          SizedBox(height: titleSpacing),
          description,
        ],
      );
}
