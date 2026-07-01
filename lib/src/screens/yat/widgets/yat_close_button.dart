import 'package:flutter/material.dart';

class YatCloseButton extends StatelessWidget {
  YatCloseButton({this.onClose});

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClose,
      child: Container(
        height: 28,
        width: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.clear,
          color: Theme.of(context).colorScheme.onSecondaryContainer,
          size: 20,
        ),
      ),
    );
  }
}
