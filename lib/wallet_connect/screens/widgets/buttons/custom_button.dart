import 'package:flutter/material.dart';

enum CustomButtonType { normal, valid, invalid }

class CustomButton extends StatelessWidget {
  final Widget child;
  final CustomButtonType type;
  final VoidCallback onTap;

  const CustomButton({
    super.key,
    required this.child,
    required this.type,
    required this.onTap,
  });

  Color _getBackgroundColor(CustomButtonType type) {
    switch (type) {
      case CustomButtonType.normal:
        return Colors.blue;
      case CustomButtonType.valid:
        return Colors.green;
      case CustomButtonType.invalid:
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: _getBackgroundColor(type),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          child: child,
        ),
      ),
    );
  }
}
