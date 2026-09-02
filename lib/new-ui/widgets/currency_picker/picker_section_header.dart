import 'package:flutter/material.dart';

class PickerSectionHeader extends StatelessWidget {
  const PickerSectionHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              letterSpacing: -0.06,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
}
