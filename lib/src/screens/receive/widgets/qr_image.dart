import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

    if (isSvg) {
      final qrSize = size ?? 100.0;
      final logoSize = qrSize * 0.30;

      return Stack(
        alignment: Alignment.center,
        children: [
          qr.QrImageView(
            data: data,
            errorCorrectionLevel: errorCorrectionLevel,
            version: version ?? qr.QrVersions.auto,
            size: qrSize,
            foregroundColor: foregroundColor,
            backgroundColor: backgroundColor,
            padding: const EdgeInsets.all(12.0),
          ),
          SvgPicture.asset(
            imagePath,
            width: logoSize * 0.8,
            height: logoSize * 0.8,
          ),
        ],
      );
    } else {
      return qr.QrImageView(
        data: data,
        errorCorrectionLevel: errorCorrectionLevel,
        version: version ?? qr.QrVersions.auto,
        size: size,
        foregroundColor: foregroundColor,
        backgroundColor: backgroundColor,
        padding: const EdgeInsets.all(12.0),
        embeddedImage: AssetImage(imagePath),
      );
    }
  }
}
