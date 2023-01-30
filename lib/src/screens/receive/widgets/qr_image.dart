import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart' as qr;

class QrImage extends StatelessWidget {
  QrImage({
    required this.data,
    this.size = 100.0,
    this.backgroundColor,
    this.foregroundColor = Colors.black,
    this.version = 9, // Previous value: 7 something happened after flutter upgrade monero wallets addresses are longer than ver. 7 ???
    this.errorCorrectionLevel = qr.QrErrorCorrectLevel.L,
  });

  final Color? backgroundColor;
  final double size;
  final String data;
  final int version;
  final int errorCorrectionLevel;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return qr.QrImage(
      data: data,
      errorCorrectionLevel: errorCorrectionLevel,
      version: version,
      size: size,
      foregroundColor: foregroundColor,
      padding: EdgeInsets.zero,
    );
  }
}
