import 'package:cake_wallet/src/widgets/svg_image_provider.dart';
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
    final imagePath = embeddedImagePath ?? 'assets/images/qr-cake.png';
    final isSvg = imagePath.endsWith('.svg');
    return qr.QrImageView(
      data: data,
      errorCorrectionLevel: errorCorrectionLevel,
      version: version ?? qr.QrVersions.auto,
      size: size,
      foregroundColor: foregroundColor,
      backgroundColor: backgroundColor,
      padding: const EdgeInsets.all(12.0),
      embeddedImage: isSvg ? SvgImageProvider(imagePath) : AssetImage(imagePath),
    );
  }
}
