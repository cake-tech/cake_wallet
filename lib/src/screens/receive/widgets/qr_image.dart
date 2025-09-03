import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart' as qr;

class QrImage extends StatelessWidget {
  QrImage({
    required this.data,
    this.foregroundColor = Colors.black,
    this.backgroundColor = Colors.white,
    this.size = 100.0,
    this.version,
    this.errorCorrectionLevel = qr.QrErrorCorrectLevel.H,
    this.embeddedImagePath,
  });

  final double? size;
  final Color foregroundColor;
  final Color backgroundColor;
  final String data;
  final int? version;
  final int errorCorrectionLevel;
  final String? embeddedImagePath;

  @override
  Widget build(BuildContext context) {
    return qr.QrImageView(
      data: data,
      errorCorrectionLevel: errorCorrectionLevel,
      version: version ?? qr.QrVersions.auto,
      size: size,
      foregroundColor: foregroundColor,
      backgroundColor: backgroundColor,
      padding: const EdgeInsets.all(8.0),
      embeddedImage: AssetImage(embeddedImagePath ?? 'assets/images/qr-cake.png'),
    );
  }
}
