import 'package:flutter/material.dart';

class EditWalletButtonWidget extends StatelessWidget {
  const EditWalletButtonWidget({
    required this.onTap,
    this.isGroup = false,
    this.isExpanded = false,
    super.key,
  });

  final bool isGroup;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Center(
            child: Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.surface,
              ),
              child: Icon(
                Icons.edit,
                size: 18,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        if (isGroup) ...{
          Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              size: 28,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        },
      ],
    );
  }
}
