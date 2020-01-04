import 'package:flutter/material.dart';
import 'package:qr/qr.dart';
import 'package:cake_wallet/src/screens/receive/qr_painter.dart';

class QrImage extends StatelessWidget {
  QrImage({
    @required String data,
    this.size = 100.0,
    this.backgroundColor,
    Color foregroundColor = Colors.black,
    int version = 7,
    int errorCorrectionLevel = QrErrorCorrectLevel.L,
  }) : _painter = new QrPainter(data, foregroundColor, version, errorCorrectionLevel);

  final QrPainter _painter;
  final Color backgroundColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return new Container(
      width: size,
      height: size,
      color: backgroundColor,
      child: CustomPaint(
        painter: _painter,
      ),
    );
  }
}