import 'package:flutter/material.dart';

class YatPageIndicator extends StatelessWidget {
  YatPageIndicator({required this.filled});

  final int filled;

  @override
  Widget build(BuildContext context) {
    return Container(
        width: 44,
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(3, (index) {
              final size = 8.0;
              final isFilled = index == filled;

              return Container(
                  height: size,
                  width: size,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.1)
                  )
              );
            })
        )
    );
  }
}