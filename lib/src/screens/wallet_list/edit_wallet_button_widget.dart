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
          GestureDetector(
            onTap: onTap,
            child: Center(
              child: Container(
                height: 40,
                width: 44,
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.surface,
                ),
                child: Icon(
                  Icons.edit,
                  size: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          if (isGroup) ...{
            SizedBox(width: 6),
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
