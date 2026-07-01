import 'package:flutter/material.dart';

class InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const InfoChip({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          color: Theme.of(context).colorScheme.surfaceContainer,
        ),
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
        child: InkWell(
          onTap: onPressed,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 5),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
}
