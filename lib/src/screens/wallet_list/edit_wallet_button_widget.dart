import 'package:flutter/material.dart';

class EditWalletButtonWidget extends StatelessWidget {
  const EditWalletButtonWidget({
    required this.width,
    required this.onTap,
    this.isGroup = false,
    this.isExpanded = false,
    super.key,
  });

  final bool isGroup;
  final double width;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      child: Row(
        children: [
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: CircleBorder()
            ),
            child: Icon(
                    Icons.edit,
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
          ),
          if (isGroup) ...{
            Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              size: 24,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          },
        ],
      ),
    );
  }
}
