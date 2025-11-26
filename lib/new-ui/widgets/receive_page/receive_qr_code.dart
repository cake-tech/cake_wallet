import 'package:flutter/material.dart';

class ReceiveQrCode extends StatelessWidget {
  const ReceiveQrCode({
    super.key,
    required this.onTap,
    required this.largeQrMode,
  });

  final VoidCallback onTap;
  final bool largeQrMode;

  @override
  Widget build(BuildContext context) {
    final double targetY = largeQrMode ? 40 : 0;

    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: targetY),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              width: largeQrMode ? 400 : 250,
              height: largeQrMode ? 400 : 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
              ),
              padding: const EdgeInsets.all(8.0),
              child: Image.asset("assets/btcqr.png"),
            ),
          );
        },
      ),
    );
  }
}
