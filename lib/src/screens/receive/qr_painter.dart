import 'package:flutter/material.dart';
import 'package:qr/qr.dart';

class QrPainter extends CustomPainter {
  QrPainter(
      String data,
      this.color,
      this.version,
      this.errorCorrectionLevel,
      ) : this._qr = new QrCode(version, errorCorrectionLevel) {
    _p.color = this.color;

    _qr.addData(data);
    _qr.make();
  }

  final QrCode _qr;
  final _p = new Paint()..style = PaintingStyle.fill;

  final int version;
  final int errorCorrectionLevel;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final squareSize = size.shortestSide / _qr.moduleCount;
    for (int x = 0; x < _qr.moduleCount; x++) {
      for (int y = 0; y < _qr.moduleCount; y++) {
        if (_qr.isDark(y, x)) {
          final squareRect = new Rect.fromLTWH(x * squareSize, y * squareSize, squareSize, squareSize);
          canvas.drawRect(squareRect, _p);
        }
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    if (oldDelegate is QrPainter) {
      return this.color != oldDelegate.color || this.errorCorrectionLevel != oldDelegate.errorCorrectionLevel ||
          this.version != oldDelegate.version;
    }
    return false;
  }
}