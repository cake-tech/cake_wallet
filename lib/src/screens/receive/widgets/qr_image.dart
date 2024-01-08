import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart' as qr;

class QrImage extends StatelessWidget {
  QrImage({
    required this.data,
    this.foregroundColor = Colors.black,
    this.backgroundColor = Colors.white,
    this.size = 100.0,
    this.version,
    this.errorCorrectionLevel = qr.QrErrorCorrectLevel.L,
  });

  final double size;
  final Color foregroundColor;
  final Color backgroundColor;
  final String data;
  final int? version;
  final int errorCorrectionLevel;

  @override
  Widget build(BuildContext context) {
    return qr.QrImageView(
      data: data,
      errorCorrectionLevel: errorCorrectionLevel,
      version: version ?? 9, // Previous value: 7 something happened after flutter upgrade monero wallets addresses are longer than ver. 7 ???
      size: size,
      foregroundColor: foregroundColor,
      backgroundColor: backgroundColor,
      padding: const EdgeInsets.all(8.0),
    );
  }
}
