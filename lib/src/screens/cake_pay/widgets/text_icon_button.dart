import 'package:flutter/material.dart';

class TextIconButton extends StatelessWidget {
  const TextIconButton({
    Key? key,
    required this.label,
    this.onTap,
  }) : super(key: key);

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ],
      ),
    );
  }
}
