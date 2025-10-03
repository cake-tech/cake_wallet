import 'package:flutter/material.dart';

class DottedDivider extends StatelessWidget {
  final Color color;

  const DottedDivider({super.key, required this.color});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: CustomPaint(
          painter: _DashedLinePainter(color: color),
        ),
      );
}

class _DashedLinePainter extends CustomPainter {
  final Color color;

  const _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    double dashWidth = 9, dashSpace = 5, startX = 0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
